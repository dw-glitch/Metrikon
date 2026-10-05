export const catalogLabels = {type:'Tipos / famílias',area:'Áreas',sector:'Setores',process:'Processos',location:'Locais de uso'} as const;
export type CatalogKind = keyof typeof catalogLabels;
export interface CatalogEntry {id:string;companyId:string;kind:CatalogKind;name:string;notes:string;active:boolean}
export interface InstrumentAsset {id:string;instrumentId:string;name:string;mimeType:string;sizeBytes:number;storagePath:string;createdAt:string}
export const ASSET_LIMIT=10*1024*1024;
export async function inspectAsset(file:File):Promise<{mimeType:string;extension:string}>{
 if(!file.size||file.size>ASSET_LIMIT)throw new Error('Escolha um PDF, JPG, PNG ou WebP de até 10 MB.');
 const b=new Uint8Array(await file.slice(0,12).arrayBuffer());const text=new TextDecoder().decode(b);
 const type=text.startsWith('%PDF-')?['application/pdf','pdf']:b[0]===0xff&&b[1]===0xd8&&b[2]===0xff?['image/jpeg','jpg']:b[0]===0x89&&text.slice(1,4)==='PNG'&&b[4]===13&&b[5]===10&&b[6]===26&&b[7]===10?['image/png','png']:text.startsWith('RIFF')&&text.slice(8,12)==='WEBP'?['image/webp','webp']:null;
 if(!type)throw new Error('O conteúdo do arquivo não corresponde a um PDF ou imagem aceitos.');
 const extensions:Record<string,string[]>={pdf:['pdf'],jpg:['jpg','jpeg'],png:['png'],webp:['webp']};
 const ext=file.name.split('.').pop()?.toLowerCase();if(!ext||!extensions[type[1]]?.includes(ext))throw new Error('A extensão e o conteúdo do arquivo precisam corresponder.');
 return {mimeType:type[0],extension:type[1]};
}
