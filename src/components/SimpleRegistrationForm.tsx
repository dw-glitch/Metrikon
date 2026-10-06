import {useState} from 'react';
import type {LIReferenceSummary,Instrument} from '../domain/types';
import {Field,Badge} from './Primitives';
import {evaluateSimple,simpleErrors,suggestExpiry,isRenewal,sccSituations,standardsQuestion,type SimpleCertificate,type SimpleRegistration} from '../domain/minimal';

export default function SimpleRegistrationForm({initial,li,busy,reviewOnly,onSave,onReview,onOpen,onCancel}:{initial:SimpleRegistration;li:LIReferenceSummary|null;busy:boolean;reviewOnly:boolean;onSave:(record:SimpleRegistration,file:File|undefined,submit:boolean)=>Promise<SimpleRegistration>;onReview:(approve:boolean,notes:string)=>Promise<void>;onOpen:(path:string)=>Promise<void>;onCancel:()=>void}){
 const [record,setRecord]=useState(initial),[file,setFile]=useState<File>(),[errors,setErrors]=useState<string[]>([]),[notes,setNotes]=useState('');
 const i=record.instrument,c=record.certificate,q=evaluateSimple(c),renewal=isRenewal(record);
 const disabled=busy||reviewOnly,fixed=disabled||renewal;
 const field=(key:keyof Instrument,label:string,type='text')=><Field label={label}><input type={type} required disabled={fixed} maxLength={type==='text'?500:undefined} min={type==='number'?1:undefined} step={type==='number'?1:undefined} value={String(i[key]??'')} onChange={e=>setRecord(r=>({...r,instrument:{...r.instrument,[key]:type==='number'?(e.target.value?Number(e.target.value):null):e.target.value}}))}/></Field>;
 const cf=(key:keyof SimpleCertificate,label:string,type='text')=><Field label={label}><input disabled={disabled||renewal&&['toleranceReferenceDocument','processTolerance'].includes(key)} type={type} maxLength={type==='text'?500:undefined} value={c[key]??''} inputMode={['processTolerance','measurementError','measurementUncertainty'].includes(key)?'decimal':undefined} onChange={e=>setRecord(r=>({...r,certificate:{...r.certificate,[key]:e.target.value}}))}/></Field>;
 function answer(key:'laboratoryAccredited'|'calibrationAccepted'|'acceptedWithRestriction'|'standardsValidation',value:string){
  setRecord(r=>({...r,certificate:{...r.certificate,[key]:value,...(key==='laboratoryAccredited'&&value!=='não'?{standardsValidation:''}:{}),...(key==='acceptedWithRestriction'&&value!=='sim'?{restrictionText:''}:{})}}));
 }
 const yes=(key:'laboratoryAccredited'|'calibrationAccepted'|'acceptedWithRestriction'|'standardsValidation',label:string)=><Field label={label}><select disabled={disabled} value={c[key]??''} onChange={e=>answer(key,e.target.value)}><option value="">Selecione</option><option value="sim">Sim</option><option value="não">Não</option></select></Field>;
 async function save(submit:boolean){
  setErrors([]);
  if(submit){const found=simpleErrors(i,{...c,attachmentPath:file?'arquivo selecionado':c.attachmentPath});if(found.length){setErrors(found);return;}}
  try{const result=await onSave(record,file,submit);setRecord(result);setFile(undefined);}catch(e){setErrors([(e as Error).message]);}
 }
 async function review(approve:boolean){
  setErrors([]);
  if(!approve&&!notes.trim()){setErrors(['Informe o motivo da devolução.']);return;}
  try{await onReview(approve,notes);}catch(e){setErrors([(e as Error).message]);}
 }
 return <form className="wizard simple-form" onSubmit={e=>{e.preventDefault();save(true);}}>
  <div className="wizard-body">
   <p className="simple-li"><strong>{i.liNumber||'Número LI automático'}</strong><small>{i.liNumber?`Linha ${i.liSource?.row||'—'} da LI`:`Próximo previsto: ${li?.nextCode||'aguardando referência'} · linha ${li?.nextRow||'—'}`}</small></p>
   {record.reviewNotes&&<p className="notice warning">Devolução: {record.reviewNotes}</p>}
   {renewal&&<p className="notice">Atualização da calibração: identificação e parâmetros do equipamento são preservados. Atualize os dados do certificado e confirme as respostas da análise.</p>}
   <h3>Dados do Equipamento</h3>
   <div className="form-grid three">
    {field('workSite','Obra *')}{field('criticality','Equipamento crítico *')}{field('serial','Código de série / identificação *')}{field('model','Modelo *')}{field('location','Local de uso *')}{field('calibrationResponsibleArea','Área/Setor responsável pela calibração do equipamento *')}{field('process','Processo *')}{field('measurementRange','Faixa de medição *')}{field('usageRange','Faixa de utilização *')}{field('periodicityMonths','Intervalo de calibrações (em meses) *','number')}{field('verificationDivision','Valor da divisão de verificação do equipamento *')}
    <Field label="Status do cadastro"><select disabled={fixed} value={i.registrationStatus} onChange={e=>setRecord(r=>({...r,instrument:{...r.instrument,registrationStatus:e.target.value as Instrument['registrationStatus']}}))}>{['ativo','inativo','desmobilizado','baixado'].map(v=><option key={v}>{v}</option>)}</select></Field>
    <Field label="Equipamento de empresa contratada?"><select disabled={fixed} value={i.contractorEquipment||'não'} onChange={e=>setRecord(r=>({...r,instrument:{...r.instrument,contractorEquipment:e.target.value as Instrument['contractorEquipment'],...(e.target.value!=='sim'?{contractorCompanyName:''}:{})}}))}><option value="não">Não</option><option value="sim">Sim</option></select></Field>
    {i.contractorEquipment==='sim'&&<Field label="Empresa contratada" hint="Informe o nome da empresa contratada."><input disabled={disabled||renewal&&Boolean(initial.instrument.contractorCompanyName?.trim())} maxLength={500} value={i.contractorCompanyName??''} onChange={e=>setRecord(r=>({...r,instrument:{...r.instrument,contractorCompanyName:e.target.value}}))}/></Field>}
   </div>
   <h3>Dados da Calibração</h3>
   <div className="form-grid three">
    {cf('laboratory','Entidade calibradora')}{cf('date','Data da calibração','date')}{cf('certificateNumber','Número do certificado')}{cf('toleranceReferenceDocument','Documento de referência da tolerância')}{cf('processTolerance','Tolerância do processo')}{cf('measurementUncertainty','Incerteza de medição')}{cf('measurementError','Erro de medição')}
    <Field label="% ou unidade"><select disabled={fixed} value={c.resultBasis} onChange={e=>setRecord(r=>({...r,certificate:{...r.certificate,resultBasis:e.target.value as SimpleCertificate['resultBasis']}}))}><option value="">Selecione</option><option>%</option><option>unidade</option></select></Field>
    <Field label="|Erro| + |Incerteza|"><output className="simple-result">{q.total||'—'} <Badge>{q.status}</Badge><small>Comparação ≤ tolerância</small></output></Field>
    {yes('laboratoryAccredited','A calibração foi realizada em laboratório acreditado?')}
   </div>
   {c.laboratoryAccredited==='não'&&<div className="standards-question">{yes('standardsValidation',standardsQuestion)}<small>Informe a conferência dos certificados dos padrões desta calibração.</small></div>}
   <div className="form-grid three">
    {yes('calibrationAccepted','Calibração aceita?')}{yes('acceptedWithRestriction','Aceito com restrição?')}
    {c.acceptedWithRestriction==='sim'&&<Field label="Restrição" hint="Descreva a restrição aplicável a esta calibração."><textarea disabled={disabled} maxLength={2000} value={c.restrictionText??''} onChange={e=>setRecord(r=>({...r,certificate:{...r.certificate,restrictionText:e.target.value}}))}/></Field>}
    <Field label="Situação do equipamento"><select disabled={disabled} value={c.decision} onChange={e=>setRecord(r=>({...r,certificate:{...r.certificate,decision:e.target.value as SimpleCertificate['decision']}}))}><option value="">Selecione a situação</option>{c.decision&&!sccSituations.includes(c.decision as typeof sccSituations[number])&&<option disabled value={c.decision}>Valor anterior: {c.decision}</option>}{sccSituations.map(v=><option key={v} value={v}>{v.toLocaleUpperCase('pt-BR')}</option>)}</select></Field>
    {cf('nextDate','Validade / vencimento da calibração','date')}
   </div>
   {!reviewOnly&&<div className="simple-suggestions"><button type="button" className="secondary" disabled={busy||q.status==='pendente'} onClick={()=>setRecord(r=>({...r,certificate:{...r.certificate,calibrationAccepted:q.status==='conforme'?'sim':'não'}}))}>Aplicar sugestão de aceitação: {q.status==='pendente'?'pendente':q.status==='conforme'?'Sim':'Não'}</button><button type="button" className="text-button" disabled={busy||!suggestExpiry(c.date,i.periodicityMonths)} onClick={()=>setRecord(r=>({...r,certificate:{...r.certificate,nextDate:suggestExpiry(c.date,i.periodicityMonths)}}))}>Sugerir vencimento pelo intervalo cadastrado</button></div>}
   <div className="simple-attachment">{!reviewOnly&&<Field label="Anexar certificado" hint="PDF, XLSX ou XLS, até 16 MB."><input disabled={busy} type="file" accept=".pdf,.xlsx,.xls" onChange={e=>setFile(e.target.files?.[0])}/></Field>}{(file||c.attachmentPath)&&<p>{file?.name||c.attachmentName||'Certificado anexado'} {!file&&<button type="button" className="text-button" onClick={()=>onOpen(c.attachmentPath)}>Abrir certificado</button>}</p>}</div>
   <p className="muted">O cálculo sugere a aceitação. O responsável confirma o cadastro; cada atualização preserva o certificado anterior.</p>
   {reviewOnly&&<Field label="Observação do responsável"><textarea maxLength={2000} disabled={busy} value={notes} onChange={e=>setNotes(e.target.value)} placeholder="Obrigatória ao devolver para correção"/></Field>}
   {errors.length>0&&<div role="alert" className="notice danger">{errors.map(e=><p key={e}>{e}</p>)}</div>}
  </div>
  <footer className="wizard-footer"><button type="button" className="secondary" disabled={busy} onClick={onCancel}>Cancelar</button><div>{reviewOnly?<><button type="button" className="secondary" disabled={busy} onClick={()=>review(false)}>Devolver para correção</button><button type="button" className="primary" disabled={busy} onClick={()=>review(true)}>Aprovar cadastro</button></>:<><button type="button" className="secondary" disabled={busy} onClick={()=>save(false)}>Salvar rascunho</button><button type="submit" className="primary" disabled={busy}>Enviar para aprovação</button></>}</div></footer>
 </form>;
}
