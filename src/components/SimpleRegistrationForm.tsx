import {useRef,useState} from 'react';
import type {LIReferenceSummary,Instrument} from '../domain/types';
import {Field,Badge} from './Primitives';
import {evaluateSimple,simpleErrors,suggestExpiry,isRenewal,sccSituations,standardsQuestion,type SimpleCertificate,type SimpleRegistration} from '../domain/minimal';

type FieldErrors=Record<string,string>;

function validDay(value:string){
 return /^\d{4}-\d{2}-\d{2}$/.test(value)&&!Number.isNaN(Date.parse(value))&&new Date(value).toISOString().slice(0,10)===value;
}

function validationByField(i:Instrument,c:SimpleCertificate,attachmentReady:boolean):FieldErrors{
 const errors:FieldErrors={};
 const required:Array<[keyof Instrument,string]>=[
  ['workSite','Informe a obra.'],
  ['criticality','Informe o equipamento crítico.'],
  ['serial','Informe o código de série / identificação.'],
  ['model','Informe o modelo.'],
  ['location','Informe o local de uso.'],
  ['calibrationResponsibleArea','Informe a área/setor responsável pela calibração.'],
  ['process','Informe o processo.'],
  ['measurementRange','Informe a faixa de medição.'],
  ['usageRange','Informe a faixa de utilização.'],
  ['verificationDivision','Informe o valor da divisão de verificação.']
 ];
 for(const [key,message] of required)if(!String(i[key]??'').trim())errors[String(key)]=message;
 if(!i.periodicityMonths||!Number.isInteger(i.periodicityMonths)||i.periodicityMonths<1)errors.periodicityMonths='Informe um intervalo de calibrações válido, em meses.';
 if(!['sim','não'].includes(i.contractorEquipment))errors.contractorEquipment='Informe se o equipamento pertence a empresa contratada.';
 if(i.contractorEquipment==='sim'&&!i.contractorCompanyName?.trim())errors.contractorCompanyName='Informe a empresa contratada.';

 if(!c.laboratory?.trim())errors.laboratory='Informe a entidade calibradora.';
 if(!c.date?.trim())errors.date='Informe a data da calibração.';
 else if(!validDay(c.date))errors.date='Informe uma data de calibração válida.';
 if(!c.certificateNumber?.trim())errors.certificateNumber='Informe o número do certificado.';
 if(!c.toleranceReferenceDocument?.trim())errors.toleranceReferenceDocument='Informe o documento de referência da tolerância.';
 if(!c.processTolerance?.trim())errors.processTolerance='Informe a tolerância do processo.';
 if(!c.measurementUncertainty?.trim())errors.measurementUncertainty='Informe a incerteza de medição.';
 if(!c.measurementError?.trim())errors.measurementError='Informe o erro de medição.';
 if(!c.resultBasis)errors.resultBasis='Selecione % ou unidade.';
 if(evaluateSimple(c).status==='pendente'&&c.processTolerance?.trim()&&c.measurementUncertainty?.trim()&&c.measurementError?.trim()&&c.resultBasis)errors.processTolerance='Revise tolerância, erro e incerteza: o cálculo precisa usar valores numéricos e tolerância positiva.';
 if(!['sim','não'].includes(c.laboratoryAccredited))errors.laboratoryAccredited='Informe se o laboratório é acreditado.';
 if(c.laboratoryAccredited==='não'&&!['sim','não'].includes(c.standardsValidation))errors.standardsValidation='Informe a validação da rastreabilidade e validade dos certificados dos padrões.';
 if(!['sim','não'].includes(c.calibrationAccepted))errors.calibrationAccepted='Informe se a calibração foi aceita.';
 if(!['sim','não'].includes(c.acceptedWithRestriction))errors.acceptedWithRestriction='Informe se a calibração foi aceita com restrição.';
 if(c.acceptedWithRestriction==='sim'&&!c.restrictionText?.trim())errors.restrictionText='Informe a restrição aplicável.';
 if(!sccSituations.includes(c.decision as typeof sccSituations[number]))errors.decision='Selecione a situação do equipamento conforme o SCC.';
 if(!c.nextDate?.trim())errors.nextDate='Informe a validade / vencimento da calibração.';
 else if(!validDay(c.nextDate))errors.nextDate='Informe uma data de vencimento válida.';
 else if(c.date&&validDay(c.date)&&c.nextDate<=c.date)errors.nextDate='O vencimento deve ser posterior à data da calibração.';
 if(!attachmentReady)errors.attachmentPath='Anexe o certificado em PDF, XLSX ou XLS.';
 return errors;
}

export default function SimpleRegistrationForm({initial,li,busy,reviewOnly,onSave,onReview,onOpen,onCancel}:{initial:SimpleRegistration;li:LIReferenceSummary|null;busy:boolean;reviewOnly:boolean;onSave:(record:SimpleRegistration,file:File|undefined,submit:boolean)=>Promise<SimpleRegistration>;onReview:(approve:boolean,notes:string)=>Promise<void>;onOpen:(path:string)=>Promise<void>;onCancel:()=>void}){
 const [record,setRecord]=useState(initial),[file,setFile]=useState<File>(),[fieldErrors,setFieldErrors]=useState<FieldErrors>({}),[formError,setFormError]=useState(''),[notes,setNotes]=useState(''),[notesError,setNotesError]=useState('');
 const formRef=useRef<HTMLFormElement>(null);
 const i=record.instrument,c=record.certificate,q=evaluateSimple(c),renewal=isRenewal(record);
 const disabled=busy||reviewOnly,fixed=disabled||renewal;
 const clearFieldError=(key:string)=>setFieldErrors(prev=>{if(!prev[key])return prev;const next={...prev};delete next[key];return next;});
 const focusFirstError=()=>requestAnimationFrame(()=>formRef.current?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus());
 const field=(key:keyof Instrument,label:string,type='text')=><Field label={label} error={fieldErrors[String(key)]}><input type={type} required disabled={fixed} maxLength={type==='text'?500:undefined} min={type==='number'?1:undefined} step={type==='number'?1:undefined} value={String(i[key]??'')} onChange={e=>{clearFieldError(String(key));setRecord(r=>({...r,instrument:{...r.instrument,[key]:type==='number'?(e.target.value?Number(e.target.value):null):e.target.value}}));}}/></Field>;
 const cf=(key:keyof SimpleCertificate,label:string,type='text')=><Field label={label} error={fieldErrors[String(key)]}><input disabled={disabled||renewal&&['toleranceReferenceDocument','processTolerance'].includes(key)} type={type} maxLength={type==='text'?500:undefined} value={c[key]??''} inputMode={['processTolerance','measurementError','measurementUncertainty'].includes(key)?'decimal':undefined} onChange={e=>{clearFieldError(String(key));setRecord(r=>({...r,certificate:{...r.certificate,[key]:e.target.value}}));}}/></Field>;
 function answer(key:'laboratoryAccredited'|'calibrationAccepted'|'acceptedWithRestriction'|'standardsValidation',value:string){
  clearFieldError(key);
  if(key==='laboratoryAccredited'&&value!=='não')clearFieldError('standardsValidation');
  if(key==='acceptedWithRestriction'&&value!=='sim')clearFieldError('restrictionText');
  setRecord(r=>({...r,certificate:{...r.certificate,[key]:value,...(key==='laboratoryAccredited'&&value!=='não'?{standardsValidation:''}:{}),...(key==='acceptedWithRestriction'&&value!=='sim'?{restrictionText:''}:{})}}));
 }
 const yes=(key:'laboratoryAccredited'|'calibrationAccepted'|'acceptedWithRestriction'|'standardsValidation',label:string)=><Field label={label} error={fieldErrors[key]}><select disabled={disabled} value={c[key]??''} onChange={e=>answer(key,e.target.value)}><option value="">Selecione</option><option value="sim">Sim</option><option value="não">Não</option></select></Field>;
 async function save(submit:boolean){
  setFormError('');
  if(submit){
   const certificateForValidation={...c,attachmentPath:file?'arquivo selecionado':c.attachmentPath};
   const found=simpleErrors(i,certificateForValidation);
   if(found.length){
    setFieldErrors(validationByField(i,certificateForValidation,Boolean(file||c.attachmentPath)));
    setFormError('Revise os campos destacados antes de enviar para aprovação.');
    focusFirstError();
    return;
   }
  }
  setFieldErrors({});
  try{const result=await onSave(record,file,submit);setRecord(result);setFile(undefined);}catch(e){setFormError((e as Error).message);}
 }
 async function review(approve:boolean){
  setFormError('');setNotesError('');
  if(!approve&&!notes.trim()){setNotesError('Informe o motivo da devolução.');focusFirstError();return;}
  try{await onReview(approve,notes);}catch(e){setFormError((e as Error).message);}
 }
 return <form ref={formRef} className="wizard simple-form" onSubmit={e=>{e.preventDefault();save(true);}}>
  <div className="wizard-body">
   <div className="registration-intro">
    <p className="simple-li"><strong>{i.liNumber||'Número LI automático'}</strong><small>{i.liNumber?`Linha ${i.liSource?.row||'—'} da LI`:`Próximo previsto: ${li?.nextCode||'aguardando referência'} · linha ${li?.nextRow||'—'}`}</small></p>
    {record.reviewNotes&&<p className="notice warning">Devolução: {record.reviewNotes}</p>}
    {renewal&&<p className="notice preserved-note"><strong>Atualização de certificado.</strong> Os dados do instrumento são preservados nesta atualização. Preencha somente os dados liberados da nova calibração e confirme a análise.</p>}
   </div>

   <section className={renewal?'form-section form-section-readonly':'form-section'}>
    <header className="form-section-heading"><div><span className="section-number">01</span><div><h3>Identificação / equipamento</h3><p>Dados cadastrais e parâmetros operacionais do instrumento.</p></div></div>{renewal&&<span className="readonly-chip">Dados preservados nesta atualização</span>}</header>
    <div className="form-grid three">
     {field('workSite','Obra *')}{field('criticality','Equipamento crítico *')}{field('serial','Código de série / identificação *')}{field('model','Modelo *')}{field('location','Local de uso *')}{field('calibrationResponsibleArea','Área/Setor responsável pela calibração do equipamento *')}{field('process','Processo *')}{field('measurementRange','Faixa de medição *')}{field('usageRange','Faixa de utilização *')}{field('periodicityMonths','Intervalo de calibrações (em meses) *','number')}{field('verificationDivision','Valor da divisão de verificação do equipamento *')}
     <Field label="Status do cadastro" error={fieldErrors.registrationStatus}><select disabled={fixed} value={i.registrationStatus} onChange={e=>{clearFieldError('registrationStatus');setRecord(r=>({...r,instrument:{...r.instrument,registrationStatus:e.target.value as Instrument['registrationStatus']}}));}}>{['ativo','inativo','desmobilizado','baixado'].map(v=><option key={v}>{v}</option>)}</select></Field>
     <Field label="Equipamento de empresa contratada?" error={fieldErrors.contractorEquipment}><select disabled={fixed} value={i.contractorEquipment||'não'} onChange={e=>{clearFieldError('contractorEquipment');clearFieldError('contractorCompanyName');setRecord(r=>({...r,instrument:{...r.instrument,contractorEquipment:e.target.value as Instrument['contractorEquipment'],...(e.target.value!=='sim'?{contractorCompanyName:''}:{})}}));}}><option value="não">Não</option><option value="sim">Sim</option></select></Field>
     {i.contractorEquipment==='sim'&&<Field label="Empresa contratada" hint="Informe o nome da empresa contratada." error={fieldErrors.contractorCompanyName}><input disabled={disabled||renewal&&Boolean(initial.instrument.contractorCompanyName?.trim())} maxLength={500} value={i.contractorCompanyName??''} onChange={e=>{clearFieldError('contractorCompanyName');setRecord(r=>({...r,instrument:{...r.instrument,contractorCompanyName:e.target.value}}));}}/></Field>}
    </div>
   </section>

   <section className="form-section">
    <header className="form-section-heading"><div><span className="section-number">02</span><div><h3>Calibração</h3><p>Dados do certificado, tolerância e resultado metrológico.</p></div></div></header>
    <div className="form-grid three">
     {cf('laboratory','Entidade calibradora')}{cf('date','Data da calibração','date')}{cf('certificateNumber','Número do certificado')}{cf('toleranceReferenceDocument','Documento de referência da tolerância')}{cf('processTolerance','Tolerância do processo')}{cf('measurementUncertainty','Incerteza de medição')}{cf('measurementError','Erro de medição')}
     <Field label="% ou unidade" error={fieldErrors.resultBasis}><select disabled={fixed} value={c.resultBasis} onChange={e=>{clearFieldError('resultBasis');setRecord(r=>({...r,certificate:{...r.certificate,resultBasis:e.target.value as SimpleCertificate['resultBasis']}}));}}><option value="">Selecione</option><option>%</option><option>unidade</option></select></Field>
     <Field label="|Erro| + |Incerteza|"><output className="simple-result">{q.total||'—'} <Badge>{q.status}</Badge><small>Comparação ≤ tolerância</small></output></Field>
     {yes('laboratoryAccredited','A calibração foi realizada em laboratório acreditado?')}
    </div>
    {c.laboratoryAccredited==='não'&&<div className="standards-question">{yes('standardsValidation',standardsQuestion)}<small>Informe a conferência dos certificados dos padrões desta calibração.</small></div>}
   </section>

   <section className="form-section">
    <header className="form-section-heading"><div><span className="section-number">03</span><div><h3>Decisão e certificado</h3><p>Confirmação da aceitação, situação, validade e evidência da calibração.</p></div></div></header>
    <div className="form-grid three">
     {yes('calibrationAccepted','Calibração aceita?')}{yes('acceptedWithRestriction','Aceito com restrição?')}
     {c.acceptedWithRestriction==='sim'&&<Field label="Restrição" hint="Descreva a restrição aplicável a esta calibração." error={fieldErrors.restrictionText}><textarea disabled={disabled} maxLength={2000} value={c.restrictionText??''} onChange={e=>{clearFieldError('restrictionText');setRecord(r=>({...r,certificate:{...r.certificate,restrictionText:e.target.value}}));}}/></Field>}
     <Field label="Situação do equipamento" error={fieldErrors.decision}><select disabled={disabled} value={c.decision} onChange={e=>{clearFieldError('decision');setRecord(r=>({...r,certificate:{...r.certificate,decision:e.target.value as SimpleCertificate['decision']}}));}}><option value="">Selecione a situação</option>{c.decision&&!sccSituations.includes(c.decision as typeof sccSituations[number])&&<option disabled value={c.decision}>Valor anterior: {c.decision}</option>}{sccSituations.map(v=><option key={v} value={v}>{v.toLocaleUpperCase('pt-BR')}</option>)}</select></Field>
     {cf('nextDate','Validade / vencimento da calibração','date')}
    </div>
    {!reviewOnly&&<div className="simple-suggestions"><button type="button" className="secondary" disabled={busy||q.status==='pendente'} onClick={()=>{clearFieldError('calibrationAccepted');setRecord(r=>({...r,certificate:{...r.certificate,calibrationAccepted:q.status==='conforme'?'sim':'não'}}));}}>Aplicar sugestão de aceitação: {q.status==='pendente'?'pendente':q.status==='conforme'?'Sim':'Não'}</button><button type="button" className="text-button" disabled={busy||!suggestExpiry(c.date,i.periodicityMonths)} onClick={()=>{clearFieldError('nextDate');setRecord(r=>({...r,certificate:{...r.certificate,nextDate:suggestExpiry(c.date,i.periodicityMonths)}}));}}>Sugerir vencimento pelo intervalo cadastrado</button></div>}
    <div className="simple-attachment"><div className="attachment-heading"><strong>Certificado de calibração</strong><small>Evidência vinculada a esta versão do cadastro.</small></div>{!reviewOnly&&<Field label="Anexar certificado" hint="PDF, XLSX ou XLS, até 16 MB." error={fieldErrors.attachmentPath}><input disabled={busy} type="file" accept=".pdf,.xlsx,.xls" onChange={e=>{clearFieldError('attachmentPath');setFile(e.target.files?.[0]);}}/></Field>}{(file||c.attachmentPath)&&<p className="attachment-current"><span>{file?.name||c.attachmentName||'Certificado anexado'}</span>{!file&&<button type="button" className="text-button" onClick={()=>onOpen(c.attachmentPath)}>Abrir certificado</button>}</p>}</div>
   </section>

   <p className="muted form-footnote">O cálculo sugere a aceitação. O responsável confirma o cadastro; cada atualização preserva o certificado anterior.</p>
   {reviewOnly&&<Field label="Observação do responsável" error={notesError}><textarea maxLength={2000} disabled={busy} value={notes} onChange={e=>{setNotesError('');setNotes(e.target.value);}} placeholder="Obrigatória ao devolver para correção"/></Field>}
   {formError&&<div role="alert" className="notice danger form-error-summary"><p>{formError}</p></div>}
  </div>
  <footer className="wizard-footer"><button type="button" className="secondary" disabled={busy} onClick={onCancel}>Cancelar</button><div>{reviewOnly?<><button type="button" className="secondary" disabled={busy} onClick={()=>review(false)}>Devolver para correção</button><button type="button" className="primary" disabled={busy} onClick={()=>review(true)}>Aprovar cadastro</button></>:<><button type="button" className="secondary" disabled={busy} onClick={()=>save(false)}>Salvar rascunho</button><button type="submit" className="primary" disabled={busy}>Enviar para aprovação</button></>}</div></footer>
 </form>;
}
