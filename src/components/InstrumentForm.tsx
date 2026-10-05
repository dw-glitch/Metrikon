import { useState } from 'react';
import type { Instrument, LIReferenceSummary } from '../domain/types';
import { Field } from './Primitives';
import type {CatalogEntry,CatalogKind} from '../domain/catalogs';

export default function InstrumentForm({
  initial,catalogs,liReference,onSave,onCancel,busy
}:{
  initial:Instrument;
  catalogs:CatalogEntry[];
  liReference:LIReferenceSummary|null;
  onSave:(i:Instrument,reason:string,evidence:string)=>Promise<void>;
  onCancel:()=>void;
  busy:boolean;
}) {
  const [draft,setDraft]=useState<Instrument>({...initial,contractorEquipment:initial.contractorEquipment||'não'});
  const [errors,setErrors]=useState<Record<string,string>>({});
  const [reason,setReason]=useState(''),[evidence,setEvidence]=useState('');

  function set<K extends keyof Instrument>(key:K,value:Instrument[K]){
    setDraft(current=>({...current,[key]:value}));
    setErrors(current=>({...current,[key]:''}));
  }

  function validate(){
    const e:Record<string,string>={};
    const required:Array<[keyof Instrument,string]>=[
      ['workSite','Obra'],
      ['criticality','Equipamento crítico'],
      ['serial','Código de série / identificação'],
      ['model','Modelo'],
      ['location','Local de uso'],
      ['calibrationResponsibleArea','Área/Setor responsável pela calibração do equipamento'],
      ['process','Processo'],
      ['measurementRange','Faixa de medição'],
      ['usageRange','Faixa de utilização'],
      ['verificationDivision','Valor da divisão de verificação do equipamento']
    ];
    for(const [key,label] of required)if(!String(draft[key]??'').trim())e[key]=`Informe ${label.toLowerCase()}.`;
    if(!initial.liNumber&&!liReference)e.liNumber='A LI oficial precisa estar carregada para atribuir o número automaticamente.';
    if(!draft.ownerCompanyId)e.ownerCompanyId='Não foi possível identificar a empresa do espaço de trabalho.';
    if(!draft.periodicityMonths||!Number.isInteger(draft.periodicityMonths)||draft.periodicityMonths<1)e.periodicityMonths='Informe o intervalo de calibrações em meses inteiros positivos.';
    if(initial.id===draft.id&&initial.liNumber&&initial.periodicityMonths!==draft.periodicityMonths&&(!reason.trim()||!evidence.trim()))e.reason='Alteração da periodicidade exige motivo e evidência.';
    return e;
  }

  const catalogInput=(key:'workSite'|'location'|'process',label:string)=>{
    const catalogKind:CatalogKind=key==='workSite'?'location':key;
    const listId=`catalog-${key}`;
    return <Field label={label} error={errors[key]}>
      <input list={listId} value={String(draft[key]||'')} aria-invalid={!!errors[key]} onChange={e=>set(key,e.target.value as never)}/>
      <datalist id={listId}>{catalogs.filter(c=>c.active&&c.companyId===draft.ownerCompanyId&&c.kind===catalogKind).map(c=><option key={c.id} value={c.name}/>)}</datalist>
    </Field>;
  };

  return <form className="wizard" onSubmit={async e=>{
    e.preventDefault();
    const found=validate();setErrors(found);
    if(Object.keys(found).length)return;
    const normalized:Instrument={
      ...draft,
      description:draft.criticality.trim(),
      type:'',manufacturer:'',tag:'',internalId:'',assetNumber:'',userCompanyId:'',
      area:'',sector:'',responsible:'',controlType:'',notes:'',capabilities:[],
      contractorEquipment:draft.contractorEquipment==='sim'?'sim':'não'
    };
    await onSave(normalized,reason,evidence);
  }}>
    <section className="wizard-body">
      <div className="section-title"><div><span className="eyebrow">CADASTRO DO INSTRUMENTO</span><h3>Dados do Equipamento</h3></div></div>
      <div className="notice">
        <strong>Número LI / N-1710 automático</strong>
        <p>{initial.liNumber
          ?`${initial.liNumber}${initial.liSource?.row?` • linha ${initial.liSource.row} da LI`:''}. Este número não pode ser alterado pelo cadastro.`
          :liReference
            ?`Próxima sequência prevista: ${liReference.nextCode} • linha ${liReference.nextRow}. O banco confirma a sequência novamente ao salvar.`
            :'LI oficial não carregada.'}</p>
        {errors.liNumber&&<p className="error">{errors.liNumber}</p>}
      </div>
      {errors.ownerCompanyId&&<div className="notice danger" role="alert">{errors.ownerCompanyId}</div>}
      <div className="form-grid three">
        {catalogInput('workSite','Obra *')}
        <Field label="Equipamento crítico *" error={errors.criticality}><input value={draft.criticality} aria-invalid={!!errors.criticality} onChange={e=>set('criticality',e.target.value)}/></Field>
        <Field label="Código de série / identificação *" error={errors.serial}><input value={draft.serial} aria-invalid={!!errors.serial} onChange={e=>set('serial',e.target.value)}/></Field>

        <Field label="Modelo *" error={errors.model}><input value={draft.model} aria-invalid={!!errors.model} onChange={e=>set('model',e.target.value)}/></Field>
        {catalogInput('location','Local de uso *')}
        <Field label="Área/Setor responsável pela calibração do equipamento *" error={errors.calibrationResponsibleArea}><input value={draft.calibrationResponsibleArea} aria-invalid={!!errors.calibrationResponsibleArea} onChange={e=>set('calibrationResponsibleArea',e.target.value)}/></Field>

        {catalogInput('process','Processo *')}
        <Field label="Faixa de medição *" error={errors.measurementRange}><input value={draft.measurementRange} aria-invalid={!!errors.measurementRange} onChange={e=>set('measurementRange',e.target.value)}/></Field>
        <Field label="Faixa de utilização *" error={errors.usageRange}><input value={draft.usageRange} aria-invalid={!!errors.usageRange} onChange={e=>set('usageRange',e.target.value)}/></Field>

        <Field label="Valor da divisão de verificação do equipamento *" error={errors.verificationDivision}><input value={draft.verificationDivision} aria-invalid={!!errors.verificationDivision} onChange={e=>set('verificationDivision',e.target.value)}/></Field>
        <Field label="Intervalo de calibrações (em meses) *" error={errors.periodicityMonths}><input type="number" min="1" step="1" value={draft.periodicityMonths??''} aria-invalid={!!errors.periodicityMonths} onChange={e=>set('periodicityMonths',e.target.value?Number(e.target.value):null)}/></Field>
        <Field label="Status do cadastro *"><select value={draft.registrationStatus} onChange={e=>set('registrationStatus',e.target.value as Instrument['registrationStatus'])}><option value="ativo">ATIVO</option><option value="inativo">INATIVO</option><option value="desmobilizado">DESMOBILIZADO</option><option value="baixado">BAIXADO</option></select></Field>
      </div>

      <label className="import-confirm">
        <input type="checkbox" checked={draft.contractorEquipment==='sim'} onChange={e=>set('contractorEquipment',e.target.checked?'sim':'não')}/>
        Equipamento de empresa contratada?
      </label>

      {initial.liNumber&&initial.periodicityMonths!==draft.periodicityMonths&&<div className="notice">
        <h4>Alteração do intervalo de calibração</h4>
        <p>Anterior: {initial.periodicityMonths??'pendente'} → novo: {draft.periodicityMonths??'pendente'} meses</p>
        <div className="form-grid">
          <Field label="Motivo" error={errors.reason}><textarea value={reason} aria-invalid={!!errors.reason} onChange={e=>setReason(e.target.value)}/></Field>
          <Field label="Evidência / referência" error={errors.reason}><input value={evidence} aria-invalid={!!errors.reason} onChange={e=>setEvidence(e.target.value)}/></Field>
        </div>
      </div>}
    </section>
    <footer className="wizard-footer">
      <button type="button" className="secondary" onClick={onCancel} disabled={busy}>Cancelar</button>
      <button type="submit" className="primary" disabled={busy}>{busy?'Salvando…':'Salvar instrumento'}</button>
    </footer>
  </form>;
}
