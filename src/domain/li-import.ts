import type {Instrument} from './types';
import {emptyInstrument,decimal} from './metrology';
export const MAX_LI_ROWS=10000;
export const importFields=[['liNumber','Número LI / N-1710'],['description','Descrição'],['tag','TAG'],['serial','Código de série / identificação'],['internalId','Identificação interna'],['assetNumber','Patrimônio'],['workSite','Obra'],['type','Tipo / família'],['manufacturer','Fabricante'],['model','Modelo'],['criticality','Equipamento crítico'],['measurementRange','Faixa de medição'],['usageRange','Faixa de utilização'],['verificationDivision','Valor da divisão de verificação'],['area','Área'],['sector','Setor'],['calibrationResponsibleArea','Área/Setor responsável pela calibração'],['process','Processo'],['location','Local de uso'],['responsible','Responsável'],['contractorEquipment','Equipamento de empresa contratada?'],['periodicityMonths','Intervalo de calibrações (meses)'],['notes','Observações'],['quantity','Grandeza'],['unit','Unidade'],['min','Mínimo da faixa'],['max','Máximo da faixa']] as const;
export type ImportField=typeof importFields[number][0];
export type ImportMapping=Partial<Record<ImportField,number>>;
export interface SheetRow {rowNumber:number;values:string[]}
export interface SheetData {sheets:string[];sheet:string;headers:string[];rows:SheetRow[]}
export interface PreviewRow {rowNumber:number;instrument:Instrument;status:'ready'|'duplicate'|'invalid';errors:string[]}
export interface ImportResultRow {rowNumber:number;code:string;outcome:'imported'|'duplicate';id?:string}
export interface ImportResult {created:number;skipped:number;rows:ImportResultRow[];batchId:string}
export const normalizeHeader=(v:string)=>v.normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase().replace(/[^a-z0-9]/g,'');
export const normalizeCode=(v:string)=>v.trim().toLowerCase();
const aliases:Record<ImportField,string[]>={liNumber:['numeroli','li','numerolin1710','codigo','codigopetrobras','codigodocumento'],description:['descricao','descricaodoinstrumento','instrumento','equipamento'],tag:['tag'],serial:['serie','numerodeserie','numerodeseriedofabricante','serial'],internalId:['identificacaointerna','idinterna'],assetNumber:['patrimonio','numeropatrimonio'],workSite:['obra'],type:['tipo','familia','tipofamilia'],manufacturer:['fabricante','marca'],model:['modelo'],criticality:['equipamentocritico','criticidade'],measurementRange:['faixademedicao'],usageRange:['faixadeutilizacao'],verificationDivision:['valordadivisaodeverificacao','divisaodeverificacao'],area:['area'],sector:['setor'],calibrationResponsibleArea:['areasetorresponsavelpelacalibracao','responsavelpelacalibracao'],process:['processo'],location:['local','localdeuso','localizacao'],responsible:['responsavel'],contractorEquipment:['equipamentodeempresacontratada','empresacontratada'],periodicityMonths:['intervalodecalibracoesmeses','periodicidademeses','periodicidade','meses'],notes:['observacoes','observacao'],quantity:['grandeza'],unit:['unidade'],min:['minimo','minimodafaixa'],max:['maximo','maximodafaixa']};
export function suggestMapping(headers:string[]):ImportMapping {const used=new Set<number>();const m:ImportMapping={};for(const [field]of importFields){const i=headers.findIndex((h,i)=>!used.has(i)&&aliases[field].includes(normalizeHeader(h)));if(i>=0){m[field]=i;used.add(i);}}return m;}
export function mappingErrors(mapping:ImportMapping):string[]{const e:string[]=[];for(const field of ['liNumber','description']as const)if(mapping[field]===undefined)e.push(`Selecione a coluna de ${field==='liNumber'?'Número LI / N-1710':'descrição'}.`);const cols=Object.values(mapping).filter(x=>x!==undefined);if(new Set(cols).size!==cols.length)e.push('Use uma coluna diferente para cada campo.');return e;}
export function buildPreview(rows:SheetRow[],mapping:ImportMapping,companyId:string,knownCodes:Iterable<string>):PreviewRow[]{
 const known=new Set(Array.from(knownCodes,normalizeCode));const counts=new Map<string,number>();
 for(const r of rows){const li=normalizeCode(r.values[mapping.liNumber??-1]||'');if(li)counts.set(li,(counts.get(li)||0)+1);}
 return rows.map(row=>{
  const i=emptyInstrument();const errors:string[]=[];
  const value=(field:ImportField)=>(row.values[mapping[field]??-1]||'').trim();
  for(const [field]of importFields)if(!['periodicityMonths','quantity','unit','min','max'].includes(field))(i as unknown as Record<string,string>)[field]=value(field);
  i.ownerCompanyId=companyId;const contractor=value('contractorEquipment').toLocaleLowerCase('pt-BR');if(contractor)i.contractorEquipment=['sim','s','yes','1'].includes(contractor)?'sim':['não','nao','n','no','0'].includes(contractor)?'não':'';if(contractor&&!i.contractorEquipment)errors.push('Equipamento de empresa contratada deve ser sim ou não.');
  if(!i.liNumber)errors.push('Número LI / N-1710 ausente.');else if(i.liNumber.length>150)errors.push('Número LI / N-1710 excede 150 caracteres.');i.code=i.liNumber;
  if(!i.description)errors.push('Descrição ausente.');else if(i.description.length>2000)errors.push('Descrição excede 2.000 caracteres.');
  if(!companyId)errors.push('Selecione uma empresa proprietária.');
  const months=value('periodicityMonths');if(months){if(!/^\d+$/.test(months)||Number(months)<1||Number(months)>2147483647)errors.push('Periodicidade deve ser informada em meses inteiros positivos.');else i.periodicityMonths=Number(months);}
  const range=[value('quantity'),value('unit'),value('min'),value('max')];
  if(range.some(Boolean)){const low=decimal(range[2]),high=decimal(range[3]);if(!range[0]||!range[1]||!low||!high||low.gt(high))errors.push('Faixa exige grandeza, unidade e mínimo ≤ máximo.');else i.capabilities=[{id:crypto.randomUUID(),quantity:range[0],unit:range[1],min:range[2],max:range[3],rangeType:'faixa informada na LI'}];}
  const code=normalizeCode(i.liNumber);const duplicate=known.has(code)||(counts.get(code)||0)>1;
  if(duplicate)errors.push(known.has(code)?'Número LI já cadastrado. O registro existente será preservado.':'Número LI repetido na planilha. Mantenha uma única linha por número na origem e gere outra prévia.');
  return {rowNumber:row.rowNumber,instrument:i,status:errors.some(x=>!x.startsWith('Número LI já')&&!x.startsWith('Número LI repetido'))?'invalid':duplicate?'duplicate':'ready',errors};
 });
}
