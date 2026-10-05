export type Accreditation = '' | 'sim' | 'não';
export interface Laboratory {
 id:string; companyId:string; name:string; cnpj:string; contact:string;
 accreditation:Accreditation; accreditationReference:string; scope:string;
 validFrom:string; validUntil:string; active:boolean; notes:string;
}
export interface ReferenceStandard {
 id:string; companyId:string; name:string; serial:string; model:string;
 quantity:string; range:string; unit:string; active:boolean; notes:string;
}
export interface StandardCertificate {
 id:string; standardId:string; companyId:string; number:string; issuer:string; issuerLaboratoryId:string;
 calibrationDate:string; validUntil:string; scope:string; traceabilityEvidence:string;
 attachmentPath:string; attachmentName:string; sizeBytes:number; version:number; supersedesId:string;
 createdAt:string; createdBy:string;
}
export interface TraceabilitySelection {certificateId:string; usage:string}
export interface TraceabilitySnapshot {
 eventDate:string; capturedAt:string;
 laboratory: {record:Laboratory; validity:string} | null;
 standards:Array<{standard:ReferenceStandard;certificate:StandardCertificate;validity:string;usage:string}>;
}
export interface TraceabilityData {laboratories:Laboratory[];standards:ReferenceStandard[];certificates:StandardCertificate[]}
export const emptyTraceability=():TraceabilityData=>({laboratories:[],standards:[],certificates:[]});
export const newLaboratory=(companyId=''):Laboratory=>({id:crypto.randomUUID(),companyId,name:'',cnpj:'',contact:'',accreditation:'',accreditationReference:'',scope:'',validFrom:'',validUntil:'',active:true,notes:''});
export const newStandard=(companyId=''):ReferenceStandard=>({id:crypto.randomUUID(),companyId,name:'',serial:'',model:'',quantity:'',range:'',unit:'',active:true,notes:''});
export const newStandardCertificate=(standard:ReferenceStandard):StandardCertificate=>({id:crypto.randomUUID(),standardId:standard.id,companyId:standard.companyId,number:'',issuer:'',issuerLaboratoryId:'',calibrationDate:'',validUntil:'',scope:'',traceabilityEvidence:'',attachmentPath:'',attachmentName:'',sizeBytes:0,version:0,supersedesId:'',createdAt:'',createdBy:''});
export function validDate(value:string):boolean {return /^\d{4}-\d{2}-\d{2}$/.test(value)&&!Number.isNaN(Date.parse(value))&&new Date(value).toISOString().slice(0,10)===value;}
export function historicalValidity(date:string,from:string,until:string):string {
 if(!validDate(date))return 'data não informada';
 if(!validDate(from)||!validDate(until))return 'validade não informada';
 if(until<from)return 'intervalo inválido';
 if(date<from)return 'posterior à calibração';
 return date>until?'vencido na data':'válido na data';
}
export function laboratoryValidity(lab:Laboratory,date:string):string {
 if(lab.accreditation==='não')return 'não acreditado';
 if(lab.accreditation!=='sim')return 'acreditação não informada';
 return historicalValidity(date,lab.validFrom,lab.validUntil);
}
export function certificateErrors(cert:StandardCertificate):string[] {
 const errors:string[]=[];
 if(!cert.number.trim()||!cert.issuer.trim())errors.push('Informe o número e a entidade emissora do certificado.');
 if(!validDate(cert.calibrationDate))errors.push('Informe a data da calibração do padrão.');
 if(cert.validUntil&&(!validDate(cert.validUntil)||cert.validUntil<cert.calibrationDate))errors.push('A validade do padrão deve ser igual ou posterior à sua calibração.');
 return errors;
}
export function captureTraceability(data:TraceabilityData,companyId:string,date:string,laboratoryId:string,selections:TraceabilitySelection[]):TraceabilitySnapshot {
 if(selections.length>100||new Set(selections.map(s=>s.certificateId)).size!==selections.length)throw new Error('Seleção de padrões inválida ou duplicada.');
 const laboratory=laboratoryId?data.laboratories.find(l=>l.id===laboratoryId&&l.companyId===companyId):null;
 if(laboratoryId&&!laboratory)throw new Error('Laboratório indisponível para esta empresa.');
 const standards=selections.map(selection=>{
  const certificate=data.certificates.find(c=>c.id===selection.certificateId&&c.companyId===companyId);
  const standard=data.standards.find(s=>s.id===certificate?.standardId&&s.companyId===companyId);
  if(!certificate||!standard)throw new Error('Certificado de padrão indisponível para esta empresa.');
  return {standard:{...standard},certificate:{...certificate},validity:historicalValidity(date,certificate.calibrationDate,certificate.validUntil),usage:selection.usage};
 });
 return structuredClone({eventDate:date,capturedAt:new Date().toISOString(),laboratory:laboratory?{record:laboratory,validity:laboratoryValidity(laboratory,date)}:null,standards});
}
