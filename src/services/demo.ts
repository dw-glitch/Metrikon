import { emptyInstrument, emptyEvent, newChecklist } from '../domain/metrology';
import type { DataState, Instrument } from '../domain/types';
export const companyId='10000000-0000-4000-8000-000000000001';
export const partnerId='10000000-0000-4000-8000-000000000002';
const prefix='CE-5290.00-22313-856-C1O-';
export function demoState(): DataState {
  const specs=[
    ['801','MANÔMETRO DIGITAL','MD-801','PD-350','0 A 350 BAR','0 A 300 BAR','0,1 BAR'],
    ['802','ALICATE AMPERÍMETRO','AA-802','AC-600','0 A 600 A','0 A 500 A','0,1 A'],
    ['803','HI-LO (ESCALA)','153202','WG-601','0 A 45 MM','0 A 45 MM','0,1 MM'],
    ['804','DURÔMETRO PORTÁTIL','DP-804','HRC-50','20 A 70 HRC','20 A 65 HRC','0,1 HRC'],
    ['805','ESQUADRO DE PRECISÃO','EP-805','EQ-300','0 A 300 MM','0 A 250 MM','0,1 MM'],
    ['806','MANÔMETRO ANALÓGICO','MA-806','MA-100','0 A 100 BAR','0 A 90 BAR','0,1 BAR']
  ];
  const today=new Date(),date=(days:number)=>new Date(today.getTime()+days*86400000).toISOString().slice(0,10);
  const instruments:Instrument[]=specs.map((s,i)=>{
    const li=`${prefix}${s[0]}`;
    return {...emptyInstrument(),
      id:`20000000-0000-4000-8000-${String(i+1).padStart(12,'0')}`,
      code:li,liNumber:li,liSource:{row:808+i,number:Number(s[0]),code:li,companyId:i===5?partnerId:companyId,origin:'planned',values:[],instrumentId:`20000000-0000-4000-8000-${String(i+1).padStart(12,'0')}`},
      description:s[1],criticality:s[1],serial:s[2],model:s[3],ownerCompanyId:i===5?partnerId:companyId,
      workSite:'RHDD',process:'QUALIDADE',location:i===5?'FRENTE DE MONTAGEM':'FRENTE DE SERVIÇO',
      calibrationResponsibleArea:'QUALIDADE',measurementRange:s[4],usageRange:s[5],verificationDivision:s[6],
      contractorEquipment:i===5?'sim':'não',periodicityMonths:12,lastControl:date(-60),nextControl:date([-5,6,20,45,90,180][i]),
      operationalStatus:i===0?'segregado':'fora de uso'
    };
  });
  return {instruments,companies:[{id:companyId,name:'CONSAG',cnpj:'',contract:'RHDD',contact:'',active:true},{id:partnerId,name:'Subcontratada • demonstração',cnpj:'',contract:'RHDD',contact:'',active:true}],events:[],audit:[],periodicities:[]};
}
export function sampleEvent(instrumentId:string) { const e=emptyEvent(instrumentId);e.checklist=newChecklist();return e; }
