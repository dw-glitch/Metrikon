import Decimal from 'decimal.js';
import type { Instrument, MetrologicalEvent, ResultPoint, ChecklistItem, Restriction, RegistrationStatus } from './types';
Decimal.set({ precision: 40 });
export const qualitativeLabels = ['Número do certificado', 'Descrição do instrumento', 'Identificação individual', 'Data da calibração/verificação', 'Resultados', 'Unidades', 'Faixa de medição', 'Procedimento/norma', 'Padrões utilizados', 'Rastreabilidade dos padrões', 'Validade dos padrões', 'Condições ambientais', 'Incerteza', 'Erro', 'Limitações de uso', 'Responsável/signatário', 'Ajustes realizados', 'Resultados antes/depois do ajuste', 'Outras informações relevantes'];
export const PROCEDURE_POINT_MARKER='[METRIKON:PROCEDIMENTO-ATUAL]';
export function newChecklist(): ChecklistItem[] { return qualitativeLabels.map((label, i) => ({ key: `q${i}`, label, outcome: '', notes: '', evidence: '' })); }
export function decimal(value: string): Decimal | null {
  if (!/^[+-]?\d+(?:[.,]\d+)?$/.test(value.trim())) return null;
  try { return new Decimal(value.trim().replace(',', '.')); } catch { return null; }
}
export interface PointEvaluation { status: 'conforme' | 'não conforme' | 'pendente'; total: string; margin: string; reason: string }
export function evaluatePoint(point: Pick<ResultPoint, 'error' | 'uncertainty' | 'tolerance' | 'unit' | 'toleranceUnit'>): PointEvaluation {
  const error = decimal(point.error), uncertainty = decimal(point.uncertainty), tolerance = decimal(point.tolerance);
  const pending = (reason: string): PointEvaluation => ({status:'pendente', total:'', margin:'', reason});
  if (!point.unit.trim() || !point.toleranceUnit.trim()) return pending('Informe as unidades do resultado e da tolerância.');
  if (point.unit.trim() !== point.toleranceUnit.trim()) return pending('Unidades diferentes: normalize e confirme antes de analisar.');
  if (!error || !uncertainty || !tolerance) return pending('Erro, incerteza e tolerância devem ser números decimais.');
  if (!tolerance.gt(0)) return pending('A tolerância do processo deve ser maior que zero.');
  const ExactDecimal=Decimal.clone({precision:Math.max(40,point.error.length+point.uncertainty.length+point.tolerance.length+8)});
  const total = new ExactDecimal(error.toFixed()).abs().plus(new ExactDecimal(uncertainty.toFixed()).abs());
  return {status:total.lt(tolerance)?'conforme':'não conforme', total:total.toFixed(), margin:new ExactDecimal(tolerance.toFixed()).minus(total).toFixed(), reason: `${total.toFixed()} < ${tolerance.toFixed()} ${point.unit}`};
}
export function evaluateCurrentProcedure(event:Pick<MetrologicalEvent,'measurementError'|'measurementUncertainty'|'processTolerance'|'resultBasis'>):PointEvaluation{
  return evaluatePoint({error:event.measurementError||'',uncertainty:event.measurementUncertainty||'',tolerance:event.processTolerance||'',unit:event.resultBasis||'',toleranceUnit:event.resultBasis||''});
}
export function isProcedurePoint(point:ResultPoint){return point.notes===PROCEDURE_POINT_MARKER;}
export function visibleResultPoints(points:ResultPoint[]){return points.filter(p=>!isProcedurePoint(p));}
export function prepareEventForPersistence(event:MetrologicalEvent):MetrologicalEvent{
  const existing=event.points.find(isProcedurePoint);
  const summary:ResultPoint={id:existing?.id||crypto.randomUUID(),reference:'',indicated:'',error:event.measurementError||'',uncertainty:event.measurementUncertainty||'',tolerance:event.processTolerance||'',unit:event.resultBasis||'',toleranceUnit:event.resultBasis||'',quantity:'Resumo do procedimento atual',k:'',veff:'',direction:'',notes:PROCEDURE_POINT_MARKER};
  return {...event,points:[summary,...visibleResultPoints(event.points)]};
}
export function combinedQuantitativeOutcome(event:MetrologicalEvent){
  const summary=evaluateCurrentProcedure(event);
  if(summary.status==='não conforme')return 'não conforme';
  if(summary.status==='pendente')return 'pendente';
  const advanced=visibleResultPoints(event.points).map(evaluatePoint);
  if(advanced.some(x=>x.status==='não conforme'))return 'não conforme';
  if(advanced.some(x=>x.status==='pendente'))return 'pendente';
  return 'conforme';
}
export function evaluateQualitative(items: ChecklistItem[]) {
  if (items.length !== qualitativeLabels.length || new Set(items.map(x=>x.key)).size !== qualitativeLabels.length || qualitativeLabels.some((_, i)=>!items.some(x=>x.key===`q${i}`))) return 'pendente';
  if (items.some(x=>x.outcome==='não conforme')) return 'não conforme';
  if (items.some(x=>!x.outcome || !['conforme','não conforme','não aplicável'].includes(x.outcome) || x.outcome==='não aplicável' && !x.notes.trim())) return 'pendente';
  return items.every(x=>x.outcome==='não aplicável')?'pendente':'conforme';
}
export function restrictionErrors(r: Restriction | null): string[] {
  if (!r) return ['Preencha a restrição de uso.'];
  const required: Array<[keyof Restriction,string]> = [['type','Tipo da restrição'],['description','Descrição'],['authorizedRange','Faixa autorizada'],['allowedProcesses','Processos permitidos'],['forbiddenProcesses','Processos não permitidos'],['deadline','Data limite'],['authorizer','Responsável pela autorização'],['evidence','Documento/evidência']];
  return required.filter(([key])=>!r[key].trim()).map(([,label])=>`${label} obrigatório.`);
}
export function currentProcedureInstrumentErrors(i:Instrument):string[]{
  const required:Array<[keyof Instrument,string]>=[['workSite','Obra'],['criticality','Equipamento crítico'],['serial','Código de série / identificação'],['model','Modelo'],['location','Local de uso'],['calibrationResponsibleArea','Área/Setor responsável pela calibração'],['process','Processo'],['measurementRange','Faixa de medição'],['usageRange','Faixa de utilização'],['verificationDivision','Valor da divisão de verificação']];
  const errors=required.filter(([key])=>!String(i[key]??'').trim()).map(([,label])=>`Preencha no cadastro: ${label}.`);
  if(!i.periodicityMonths||!Number.isInteger(i.periodicityMonths)||i.periodicityMonths<1)errors.push('Preencha no cadastro: Intervalo de calibrações (meses).');
  if(!['sim','não'].includes(i.contractorEquipment))errors.push('Informe no cadastro se é equipamento de empresa contratada.');
  return errors;
}
export function decisionErrors(event: MetrologicalEvent): string[] {
  const errors: string[]=[];
  if (!event.date) errors.push('Informe a data da calibração/verificação.');
  if (!event.laboratory.trim()) errors.push('Informe a entidade calibradora.');
  if (!event.certificateNumber.trim()) errors.push('Informe o número do certificado/registro.');
  if (!event.attachmentPath) errors.push('Anexe o certificado/registro em PDF, XLSX ou XLS.');
  if (!event.toleranceReferenceDocument.trim()) errors.push('Informe o documento de referência da tolerância.');
  if (!event.resultBasis) errors.push('Informe se os valores estão em % ou unidade.');
  if (!event.measurementError.trim()) errors.push('Informe o erro de medição.');
  if (!event.measurementUncertainty.trim()) errors.push('Informe a incerteza de medição.');
  if (!event.processTolerance.trim()) errors.push('Informe a tolerância do processo.');
  const summary=evaluateCurrentProcedure(event);
  if(summary.status==='pendente'&&event.measurementError.trim()&&event.measurementUncertainty.trim()&&event.processTolerance.trim()&&event.resultBasis)errors.push(summary.reason);
  if (!['sim','não'].includes(event.laboratoryAccredited)) errors.push('Informe se o laboratório é acreditado.');
  if (!['sim','não'].includes(event.calibrationAccepted)) errors.push('Informe se a calibração é aceita.');
  if (!['sim','não'].includes(event.acceptedWithRestriction)) errors.push('Informe se foi aceita com restrição.');
  if (!['ativo','inativo','desmobilizado','baixado'].includes(event.registrationStatus as RegistrationStatus)) errors.push('Informe o status do cadastro.');
  if (!event.rationale.trim()) errors.push('Registre a justificativa/conclusão humana.');
  if (!event.decision) errors.push('Escolha a situação do equipamento.');
  if (event.nextDate && event.nextDate<=event.date) errors.push('A próxima data deve ser posterior ao evento.');
  if (event.decision==='liberado para uso') {
    if (evaluateQualitative(event.checklist)!=='conforme') errors.push('Liberação depende de análise qualitativa conforme (PR 220 42, 3.1.7).');
    if (combinedQuantitativeOutcome(event)!=='conforme') errors.push('Liberação depende de análise quantitativa conforme.');
  }
  if (event.decision==='uso condicionado') errors.push(...restrictionErrors(event.restriction));
  return errors;
}
export function identityDifferences(instrument: Instrument, event: MetrologicalEvent) {
  return (['serial','tag','manufacturer','model'] as const).filter(k=>event.certificateIdentity[k].trim() && instrument[k].trim().toLowerCase()!==event.certificateIdentity[k].trim().toLowerCase()).map(k=>({field:k, registered:instrument[k], certificate:event.certificateIdentity[k]}));
}
export function daysUntil(date:string, today=new Date().toLocaleDateString('en-CA',{timeZone:'America/Sao_Paulo'})): number | null {
  if(!/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  return Math.round((Date.parse(`${date}T00:00:00Z`)-Date.parse(`${today}T00:00:00Z`))/86400000);
}
export function instrumentStatus(i:Instrument, events:MetrologicalEvent[]) {
  const latest=events.filter(e=>e.instrumentId===i.id).sort((a,b)=>b.date.localeCompare(a.date)||b.createdAt.localeCompare(a.createdAt))[0];
  if(latest && latest.workflow!=='concluído')return 'em análise';
  if(latest?.points.some(p=>evaluatePoint(p).status==='não conforme') || latest && evaluateQualitative(latest.checklist)==='não conforme')return 'reprovado';
  const days=daysUntil(i.nextControl);
  if(days!==null && days<0)return 'vencido';
  return latest?.workflow==='concluído' && latest.decision==='liberado para uso'?'válido':'em análise';
}
export function emptyInstrument():Instrument { return {id:crypto.randomUUID(),code:'',type:'',description:'',manufacturer:'',model:'',serial:'',tag:'',internalId:'',assetNumber:'',liNumber:'',ownerCompanyId:'',userCompanyId:'',workSite:'',area:'',sector:'',process:'',location:'',responsible:'',calibrationResponsibleArea:'',measurementRange:'',usageRange:'',verificationDivision:'',contractorEquipment:'',criticality:'',controlType:'',periodicityMonths:null,registrationStatus:'ativo',operationalStatus:'fora de uso',lastControl:'',nextControl:'',notes:'',capabilities:[]}; }
export function emptyEvent(instrumentId:string,registrationStatus:RegistrationStatus|''=''):MetrologicalEvent { return {id:crypto.randomUUID(),instrumentId,type:'calibração externa',date:'',nextDate:'',certificateNumber:'',laboratory:'',laboratoryAccredited:'',workflow:'análise em andamento',toleranceReferenceDocument:'',processTolerance:'',measurementUncertainty:'',measurementError:'',resultBasis:'',calibrationAccepted:'',acceptedWithRestriction:'',registrationStatus,points:[],checklist:newChecklist(),decision:'',rationale:'',restriction:null,attachmentPath:'',certificateIdentity:{serial:'',tag:'',manufacturer:'',model:''},divergenceJustification:'',createdAt:new Date().toISOString()}; }
