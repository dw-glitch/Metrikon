import {test} from 'node:test';
import assert from 'node:assert/strict';
import {captureTraceability,certificateErrors,historicalValidity,laboratoryValidity,newLaboratory,newStandard,newStandardCertificate,type TraceabilityData} from '../src/domain/traceability';
test('padrões: validade histórica inclusiva usa a data do evento',()=>{
 assert.equal(historicalValidity('2025-06-01','2025-01-01','2025-12-31'),'válido na data');
 assert.equal(historicalValidity('2025-12-31','2025-01-01','2025-12-31'),'válido na data');
 assert.equal(historicalValidity('2026-01-01','2025-01-01','2025-12-31'),'vencido na data');
 assert.equal(historicalValidity('2024-12-31','2025-01-01','2025-12-31'),'posterior à calibração');
 assert.equal(historicalValidity('2025-06-01','2025-01-01',''),'validade não informada');
 assert.equal(historicalValidity('2025-02-30','2025-01-01','2025-12-31'),'data não informada');
});
test('laboratório: acreditação não decide aceitação e ausência de data não presume validade',()=>{
 const lab={...newLaboratory('company'),accreditation:'sim' as const};
 assert.equal(laboratoryValidity(lab,'2025-06-01'),'validade não informada');
 assert.equal(laboratoryValidity({...lab,accreditation:'não'},'2025-06-01'),'não acreditado');
});
test('rastreamento: snapshots não mudam com renovação/inativação do catálogo',()=>{
 const lab={...newLaboratory('company'),name:'Laboratório original'};
 const standard={...newStandard('company'),name:'Padrão original',serial:'PAD-01'};
 const certificate={...newStandardCertificate(standard),number:'CERT-01',issuer:'Emissor',calibrationDate:'2025-01-01',validUntil:'2025-12-31',version:1};
 const data:TraceabilityData={laboratories:[lab],standards:[standard],certificates:[certificate]};
 const snapshot=captureTraceability(data,'company','2025-06-01',lab.id,[{certificateId:certificate.id,usage:'Escala inferior'}]);
 lab.name='Nome atualizado';standard.active=false;certificate.validUntil='2030-01-01';
 assert.equal(snapshot.laboratory?.record.name,'Laboratório original');assert.equal(snapshot.standards[0].standard.active,true);
 assert.equal(snapshot.standards[0].certificate.validUntil,'2025-12-31');assert.equal(snapshot.standards[0].validity,'válido na data');
 assert.throws(()=>captureTraceability(data,'other','2025-06-01',lab.id,[]),/empresa/);
 assert.throws(()=>captureTraceability(data,'company','2025-06-01','',[{certificateId:certificate.id,usage:''},{certificateId:certificate.id,usage:''}]),/duplicada/);
});
test('certificado: datas inválidas e validade anterior são rejeitadas; falta de validade continua explícita',()=>{
 const cert={...newStandardCertificate(newStandard('company')),number:'01',issuer:'Emissor',calibrationDate:'2025-01-01'};
 assert.deepEqual(certificateErrors(cert),[]);
 assert.ok(certificateErrors({...cert,validUntil:'2024-12-31'}).length);
 assert.ok(certificateErrors({...cert,calibrationDate:'2025-02-30'}).length);
});
