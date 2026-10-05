export type RegistrationStatus = 'ativo' | 'inativo' | 'desmobilizado' | 'baixado';
export type OperationalStatus = 'liberado para uso' | 'uso condicionado' | 'fora de uso' | 'segregado';
export type MetrologicalStatus = 'válido' | 'a vencer' | 'vencido' | 'em análise' | 'reprovado';
export type Workflow = 'aguardando envio' | 'em calibração' | 'certificado recebido' | 'análise em andamento' | 'concluído';
export type Role = 'owner' | 'quality_admin' | 'analyst' | 'inspector' | 'contractor' | 'viewer';
export type YesNo = '' | 'sim' | 'não';
export type ResultBasis = '' | '%' | 'unidade';
export interface Company { id: string; name: string; cnpj: string; contract: string; contact: string; active: boolean }
export interface Capability { id: string; quantity: string; unit: string; min: string; max: string; rangeType: string }
export interface Instrument {
  id: string; code: string; type: string; description: string; manufacturer: string; model: string;
  serial: string; tag: string; internalId: string; assetNumber: string; liNumber: string; ownerCompanyId: string;
  userCompanyId: string; workSite: string; area: string; sector: string; process: string; location: string; responsible: string;
  calibrationResponsibleArea: string; measurementRange: string; usageRange: string; verificationDivision: string;
  contractorEquipment: YesNo; criticality: string; controlType: 'calibração externa' | 'verificação interna' | '';
  periodicityMonths: number | null; registrationStatus: RegistrationStatus; operationalStatus: OperationalStatus;
  lastControl: string; nextControl: string; notes: string; capabilities: Capability[];
}
export interface ResultPoint { id: string; reference: string; indicated: string; error: string; uncertainty: string; tolerance: string; unit: string; toleranceUnit: string; quantity: string; k: string; veff: string; direction: string; notes: string }
export interface ChecklistItem { key: string; label: string; outcome: '' | 'conforme' | 'não conforme' | 'não aplicável'; notes: string; evidence: string }
export interface Restriction { type: string; description: string; authorizedRange: string; allowedProcesses: string; forbiddenProcesses: string; deadline: string; authorizer: string; evidence: string; notes: string }
export interface MetrologicalEvent {
  id: string; instrumentId: string; type: 'calibração externa' | 'verificação interna'; date: string; nextDate: string;
  certificateNumber: string; laboratory: string; laboratoryAccredited: YesNo; workflow: Workflow;
  toleranceReferenceDocument: string; processTolerance: string; measurementUncertainty: string; measurementError: string;
  resultBasis: ResultBasis; calibrationAccepted: YesNo; acceptedWithRestriction: YesNo; registrationStatus: RegistrationStatus | '';
  points: ResultPoint[]; checklist: ChecklistItem[]; decision: OperationalStatus | ''; rationale: string; restriction: Restriction | null;
  attachmentPath: string; certificateIdentity: { serial: string; tag: string; manufacturer: string; model: string };
  divergenceJustification: string; createdAt: string;
}
export interface AuditEntry { id: string; at: string; actor: string; action: string; entity: string; before: unknown; after: unknown; reason: string }
export interface PeriodicityEntry { id: string; instrumentId: string; previous: number | null; next: number | null; reason: string; evidence: string; actor: string; at: string }
export interface DataState { instruments: Instrument[]; companies: Company[]; events: MetrologicalEvent[]; audit: AuditEntry[]; periodicities: PeriodicityEntry[] }
