from pathlib import Path
import tempfile, shutil, subprocess, json, datetime, importlib.util, unittest, os
W=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('due',W/'config/scripts/signal-due.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class RuntimeTests(unittest.TestCase):
 def test_weekly_due_on_tuesday(self):self.assertIn('weekly-review',m.due_signals({'weekly-review':{'last-fired':'2026-09-01'}},datetime.date(2026,9,8)))
 def test_never_run_and_null(self):self.assertEqual(len(m.due_signals({'weekly-review':{'last-fired':None}},datetime.date(2026,9,8))),3)
 def test_recent_weekly(self):self.assertNotIn('weekly-review',m.due_signals({'weekly-review':{'last-fired':'2026-09-07'}},datetime.date(2026,9,8)))
 def test_suppressed(self):self.assertNotIn('vault-improvements',m.due_signals({'vault-improvements':{'suppressed-until':'2026-09-09'}},datetime.date(2026,9,8)))
 def test_expiry_boundary(self):self.assertIn('vault-improvements',m.due_signals({'vault-improvements':{'suppressed-until':'2026-09-08'}},datetime.date(2026,9,8)))
 def test_malformed_date(self):self.assertIn('weekly-review',m.due_signals({'weekly-review':{'last-fired':'bad'}},datetime.date(2026,9,8)))
 def test_future_date(self):self.assertIn('weekly-review',m.due_signals({'weekly-review':{'last-fired':'2027-01-01'}},datetime.date(2026,9,8)))
 def test_scans_never_overwrite_shared_state(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);v=root/'vault';scripts=v/'config/scripts';scripts.mkdir(parents=True);state=v/'config/state';state.mkdir();old=state/'session-entry.md';old.write_text('preserved historical scan')
   for name in ['session-entry-scan.sh','signal-due.py']:shutil.copy2(W/'config/scripts'/name,scripts/name)
   for host in ['host-a','host-b']:
    env=dict(os.environ,CLAUDE_PROJECT_DIR=str(v),WORKDESK_STATE_HOME=str(root/host));r=subprocess.run(['bash',str(scripts/'session-entry-scan.sh')],env=env,capture_output=True,text=True)
    self.assertEqual(r.returncode,0,r.stderr);self.assertIn('host-local',json.loads(r.stdout)['hookSpecificOutput']['additionalContext']);self.assertEqual(len(list((root/host).rglob('session-entry.md'))),1)
   self.assertEqual(old.read_text(),'preserved historical scan')
 def test_corrupt_state_visible(self):
  with tempfile.TemporaryDirectory() as t:
   p=Path(t)/'signals.json';p.write_text('{bad');r=subprocess.run(['python3',str(W/'config/scripts/signal-due.py'),str(p)],capture_output=True,text=True);self.assertEqual(r.returncode,2);self.assertIn('unreadable',r.stderr)
class MigrationIntegrationTests(unittest.TestCase):
 def setup_fixture(self,root):
  vault=root/'vault';cfg=vault/'config';stage=root/'staging';incoming=stage/'workdesk'
  for d in [cfg/'defaults',incoming]:d.mkdir(parents=True)
  for name in ['a.txt','b.txt']:
   (cfg/name).write_text('before');(cfg/'defaults'/name).write_text('before');(incoming/name).write_text('after')
  (cfg/'VERSION').write_text('1.0.0');(cfg/'defaults/VERSION').write_text('1.0.0');(incoming/'VERSION').write_text('1.0.1')
  (stage/'manifest.json').write_text(json.dumps({'version':'1.0.1','migrations':[]}));res=root/'resolutions.json';res.write_text(json.dumps({'b.txt':{'resolution':'theirs'}}))
  import hashlib
  expected=hashlib.sha256(b'before').hexdigest();review={'files':{name:{'operator_sha256':expected} for name in ['a.txt','b.txt']}}
  (stage/'reviewed-plan.json').write_text(json.dumps(review));return vault,cfg,stage,res,review
 def apply(self,vault,stage,res):return subprocess.run(['bash',str(W/'config/scripts/migrate.sh'),'apply',str(stage),str(res)],env=dict(os.environ,CLAUDE_PROJECT_DIR=str(vault)),capture_output=True,text=True)
 def test_concurrent_change_preserved_then_reviewed_retry(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);vault,cfg,stage,res,review=self.setup_fixture(root);(cfg/'b.txt').write_text('other-agent')
   r=self.apply(vault,stage,res);self.assertNotEqual(r.returncode,0);self.assertEqual((cfg/'b.txt').read_text(),'other-agent');self.assertEqual((cfg/'a.txt').read_text(),'after');self.assertEqual((cfg/'VERSION').read_text(),'1.0.0');self.assertTrue(list((vault/'.workdesk-backups').iterdir()))
   import hashlib
   review['files']['b.txt']['operator_sha256']=hashlib.sha256(b'other-agent').hexdigest();(stage/'reviewed-plan.json').write_text(json.dumps(review))
   r=self.apply(vault,stage,res);self.assertEqual(r.returncode,0,r.stderr);self.assertEqual((cfg/'VERSION').read_text().strip(),'1.0.1');self.assertEqual((cfg/'b.txt').read_text(),'after');self.assertEqual(len(list((vault/'.workdesk-backups').iterdir())),2)
 def test_symlink_seen_before_any_copy(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);vault,cfg,stage,res,review=self.setup_fixture(root);(cfg/'b.txt').unlink();external=root/'external';external.write_text('before');(cfg/'b.txt').symlink_to(external)
   r=self.apply(vault,stage,res);self.assertNotEqual(r.returncode,0);self.assertIn('Symlink targets',r.stderr);self.assertEqual((cfg/'a.txt').read_text(),'before');self.assertEqual(external.read_text(),'before')
 def test_old_migration_skipped(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);vault,cfg,stage,res,review=self.setup_fixture(root);m=stage/'migrations';m.mkdir();name='0.9.0-to-1.0.0-obsolete.sh';(m/name).write_text('exit 77\n');(stage/'manifest.json').write_text(json.dumps({'version':'1.0.1','migrations':[name]}))
   r=self.apply(vault,stage,res);self.assertEqual(r.returncode,0,r.stderr)

class CopyTests(unittest.TestCase):
 def test_idempotence_conflict_and_snapshot(self):
  spec=importlib.util.spec_from_file_location('copy_checked',W/'config/scripts/checked-file-copy.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);src=root/'source';dst=root/'target';snap=root/'before';src.write_text('after');dst.write_text('before');old=c.digest(dst)
   self.assertEqual(c.checked_copy(src,dst,old,snap),'applied');self.assertEqual(snap.read_text(),'before')
   self.assertEqual(c.checked_copy(src,dst,old,snap),'no-op')
   dst.write_text('other-agent-edit')
   with self.assertRaises(c.ChangedTarget):c.checked_copy(src,dst,old)
   self.assertEqual(dst.read_text(),'other-agent-edit')
 def test_symlink_target_refused(self):
  spec=importlib.util.spec_from_file_location('copy_checked',W/'config/scripts/checked-file-copy.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);src=root/'source';src.write_text('safe');dst=root/'link';dst.symlink_to(src)
   with self.assertRaises(c.ChangedTarget):c.checked_copy(src,dst,None)

class HealthTests(unittest.TestCase):
 def test_pending_commit_and_push_thresholds(self):
  spec=importlib.util.spec_from_file_location('health',W/'config/scripts/workdesk-health.py');h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
  self.assertEqual(len(h.backup_status(True,1900,7300,True,False)),2)
  self.assertEqual(h.backup_status(False,9000,None,True,True),[])
  self.assertIn('push-marker-unavailable',h.backup_status(False,0,None,False,False))

class LinkTests(unittest.TestCase):
 def run_case(self, content, notes, expected):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);scripts=root/'config/scripts';scripts.mkdir(parents=True)
   for name in ['check-wikilinks.sh','check-wikilinks.py']:shutil.copy2(W/'config/scripts'/name,scripts/name)
   for name in notes:
    p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('fixture')
   source=root/'test.md';source.write_text(content)
   r=subprocess.run(['bash',str(scripts/'check-wikilinks.sh'),str(source)],capture_output=True,text=True)
   self.assertEqual(r.returncode,expected,r.stdout+r.stderr)
 def test_historical_target(self):self.run_case('[[system/transcripts/past]]', ['system/transcripts/past.md'],0)
 def test_wrong_path(self):self.run_case('[[wrong/past]]',['atlas/past.md'],1)
 def test_alias_heading_extension(self):self.run_case('[[atlas/past.md#Heading|Alias]]',['atlas/past.md'],0)
 def test_tilde_fence_and_nested_inline(self):self.run_case('~~~md\n[[missing]]\n~~~\n`` `[ACTION] fake` ``',['valid.md'],0)
 def test_real_inbox_reference(self):self.run_case('`[ACTION] real`',['gtd/inbox/[ACTION] real.md'],0)
 def test_ambiguous_basename(self):self.run_case('[[same]]',['atlas/a/same.md','atlas/b/same.md'],1)
 def test_attachment_basename(self):self.run_case('![[diagram.png]]',['system/media/diagram.png'],0)
 def test_missing_signal_state(self):
  r=subprocess.run(['python3',str(W/'config/scripts/signal-due.py'),str(W/'absent-signal-state.json')],capture_output=True,text=True);self.assertEqual(r.returncode,2)
 def test_missing_media(self):self.run_case('![[missing.png]]',[],1)
 def test_missing_input_fails(self):
  r=subprocess.run(['bash',str(W/'config/scripts/check-wikilinks.sh'),str(W/'missing-fixture.md')],capture_output=True,text=True);self.assertEqual(r.returncode,2)

if __name__=='__main__':unittest.main(verbosity=2)
