import type {Instrument,RegistrationStatus} from './types';
import {emptyInstrument} from './metrology';
export const MAX_LI_ROWS=10000;

export const importFields=[
 ['liNumber','Número LI / N-1710'],
 ['workSite','Obra'],
 ['criticality','Equipamento crítico'],
 ['serial','Código de série / identificação'],
 ['model','Modelo'],
 ['location','Local de uso'],
 ['calibrationResponsibleArea','Área/Setor responsável pela calibração do equipamento'],
 ['process','Processo'],
 ['measurementRange','Faixa de medição'],
 ['usageRange','Faixa de utilização'],
 ['periodicityMonths','Intervalo de calibrações (em meses)'],
 ['verificationDivision','Valor da divisão de verificação do equipamento'],
 ['registrationStatus','Status do cadastro'],
 ['contractorEquipment','Equipamento de empresa contratada?']
] as const;

export type ImportField=typeof importFields[number][0];
export type ImportMapping=Partial<Record<ImportField,number>>;
export interface SheetRow {rowNumber:number;values:string[]}
export interface SheetData {sheets:string[];sheet:string;headers:string[];rows:SheetRow[]}
export interface PreviewRow {rowNumber:number;instrument:Instrument;status:'ready'|'duplicate'|'invalid';errors:string[]}
export interface ImportResultRow {rowNumber:number;code:string;outcome:'imported'|'duplicate';id?:string}
export interface ImportResult {created:number;skipped:number;rows:ImportResultRow[];batchId:string}
export const normalizeHeader=(v:string)=>v.normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase().replace(/[^a-z0-9]/g,'');
export const normalizeCode=(v:string)=>v.trim().toLowerCase();

const aliases:Record<ImportField,string[]>={
 liNumber:['numeroli','li','numerolin1710','codigo','codigopetrobras','codigodocumento'],
 workSite:['obra'],
 criticality:['equipamentocritico','criticidade','descricao','descricaodoinstrumento','instrumento','equipamento'],
 serial:['codigodeserieidentificacao','serie','numerodeserie','numerodeseriedofabricante','serial'],
 model:['modelo'],
 location:['local','localdeuso','localizacao'],
 calibrationResponsibleArea:['areasetorresponsavelpelacalibracaodoequipamento','areasetorresponsavelpelacalibracao','responsavelpelacalibracao'],
 process:['processo'],
 measurementRange:['faixademedicao'],
 usageRange:['faixadeutilizacao'],
 periodicityMonths:['intervalodecalibracoesemmeses','intervalodecalibracoesmeses','periodicidademeses','periodicidade','meses'],
 verificationDivision:['valordadivisaodeverificacaodoequipamento','valordadivisaodeverificacao','divisaodeverificacao'],
 registrationStatus:['statusdocadastro'],
 contractorEquipment:['equipamentodeempresacontratada','empresacontratada']
};

export function suggestMapping(headers:string[]):ImportMapping {
 const used=new Set<number>(),mapping:ImportMapping={};
 for(const [field]of importFields){
  const index=headers.findIndex((header,i)=>!used.has(i)&&aliases[field].includes(normalizeHeader(header)));
  if(index>=0){mapping[field]=index;used.add(index);}
 }
 return mapping;
}

export function mappingErrors(mapping:ImportMapping):string[]{
 const errors:string[]=[];
 for(const field of ['liNumber','criticality']as const)if(mapping[field]===undefined)errors.push(`Selecione a coluna de ${field==='liNumber'?'Número LI / N-1710':'Equipamento crítico'}.`);
 const columns=Object.values(mapping).filter(x=>x!==undefined);
 if(new Set(columns).size!==columns.length)errors.push('Use uma coluna diferente para cada campo.');
 return errors;
}

export function buildPreview(rows:SheetRow[],mapping:ImportMapping,companyId:string,knownCodes:Iterable<string>):PreviewRow[]{
 const known=new Set(Array.from(knownCodes,normalizeCode)),counts=new Map<string,number>();
 for(const row of rows){const li=normalizeCode(row.values[mapping.liNumber??-1]||'');if(li)counts.set(li,(counts.get(li)||0)+1);}
 return rows.map(row=>{
  const instrument=emptyInstrument(),errors:string[]=[];
  const value=(field:ImportField)=>(row.values[mapping[field]??-1]||'').trim();
  instrument.ownerCompanyId=companyId;
  instrument.liNumber=value('liNumber');
  instrument.code=instrument.liNumber;
  instrument.workSite=value('workSite');
  instrument.criticality=value('criticality');
  instrument.description=instrument.criticality;
  instrument.serial=value('serial');
  instrument.model=value('model');
  instrument.location=value('location');
  instrument.calibrationResponsibleArea=value('calibrationResponsibleArea');
  instrument.process=value('process');
  instrument.measurementRange=value('measurementRange');
  instrument.usageRange=value('usageRange');
  instrument.verificationDivision=value('verificationDivision');

  const months=value('periodicityMonths');
  if(months){
   if(!/^\d+$/.test(months)||Number(months)<1||Number(months)>2147483647)errors.push('Intervalo de calibrações deve ser informado em meses inteiros positivos.');
   else instrument.periodicityMonths=Number(months);
  }

  const contractor=value('contractorEquipment').toLocaleLowerCase('pt-BR');
  if(contractor){
   instrument.contractorEquipment=['sim','s','yes','1','true'].includes(contractor)?'sim':['não','nao','n','no','0','false'].includes(contractor)?'não':'';
   if(!instrument.contractorEquipment)errors.push('Equipamento de empresa contratada deve ser sim ou não.');
  }

  const registration=value('registrationStatus').toLocaleLowerCase('pt-BR') as RegistrationStatus;
  if(registration){
   if(['ativo','inativo','desmobilizado','baixado'].includes(registration))instrument.registrationStatus=registration;
   else errors.push('Status do cadastro deve ser ativo, inativo, desmobilizado ou baixado.');
  }

  if(!instrument.liNumber)errors.push('Número LI / N-1710 ausente.');
  else if(instrument.liNumber.length>150)errors.push('Número LI / N-1710 excede 150 caracteres.');
  if(!instrument.criticality)errors.push('Equipamento crítico ausente.');
  else if(instrument.criticality.length>2000)errors.push('Equipamento crítico excede 2.000 caracteres.');
  if(!companyId)errors.push('Não foi possível identificar a empresa do espaço de trabalho.');

  const normalized=normalizeCode(instrument.liNumber);
  const duplicate=known.has(normalized)||(counts.get(normalized)||0)>1;
  if(duplicate)errors.push(known.has(normalized)?'Número LI já cadastrado. O registro existente será preservado.':'Número LI repetido na planilha. Mantenha uma única linha por número na origem e gere outra prévia.');

  return {
   rowNumber:row.rowNumber,
   instrument,
   status:errors.some(x=>!x.startsWith('Número LI já')&&!x.startsWith('Número LI repetido'))?'invalid':duplicate?'duplicate':'ready',
   errors
  };
 });
}
