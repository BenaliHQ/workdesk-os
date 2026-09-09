import test from 'node:test';
import assert from 'node:assert/strict';
import {missingChunks} from '../config/scripts/verify-search-index.mjs';
const chunks=[{pos:0},{pos:100},{pos:200}];
const row=seq=>({hash:'fixture',seq,pos:chunks[seq].pos,model:'embeddinggemma'});
const metadata=seqs=>new Map(seqs.map(seq=>[`fixture_${seq}`,row(seq)]));
const vectors=seqs=>new Set(seqs.map(seq=>`fixture_${seq}`));
test('complete matching sequence passes',()=>assert.deepEqual(missingChunks('fixture',chunks,metadata([0,1,2]),vectors([0,1,2]),'embeddinggemma'),[]));
test('trailing loss fails despite first vector',()=>assert.deepEqual(missingChunks('fixture',chunks,metadata([0,1]),vectors([0,1]),'embeddinggemma'),[{hash:'fixture',seq:2,reason:'missing-chunk'}]));
test('interior loss fails',()=>assert.equal(missingChunks('fixture',chunks,metadata([0,2]),vectors([0,2]),'embeddinggemma')[0].seq,1));
test('metadata without stored vector fails',()=>assert.equal(missingChunks('fixture',chunks,metadata([0,1,2]),vectors([0,2]),'embeddinggemma')[0].reason,'missing-chunk'));
test('wrong position or model fails',()=>{
  const m=metadata([0,1,2]);m.get('fixture_1').pos=99;m.get('fixture_2').model='other';
  assert.equal(missingChunks('fixture',chunks,m,vectors([0,1,2]),'embeddinggemma').length,2);
});
