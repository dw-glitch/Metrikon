import * as XLSX from 'xlsx';
import {MAX_LI_ROWS,type SheetData} from '../domain/li-import';
export function readSheet(buffer:ArrayBuffer,sheetName?:string,headerRow=1):SheetData{
 if(!Number.isInteger(headerRow)||headerRow<1||headerRow>30)throw new Error('A linha do cabeçalho deve estar entre 1 e 30.');
 const bytes=new Uint8Array(buffer);const binary=(bytes[0]===0x50&&bytes[1]===0x4b)||(bytes[0]===0xd0&&bytes[1]===0xcf);
 let input:ArrayBuffer|string=buffer;if(!binary){try{input=new TextDecoder('utf-8',{fatal:true}).decode(buffer);}catch{input=new TextDecoder('windows-1252').decode(buffer);}}
 const book=XLSX.read(input,{type:binary?'array':'string',raw:true,cellDates:false,sheetRows:MAX_LI_ROWS+31,sheets:sheetName??0});
 const name=sheetName||book.SheetNames[0];const sheet=book.Sheets[name];if(!sheet)throw new Error('Escolha uma aba válida.');
 const ref=sheet['!fullref']||sheet['!ref'];if(!ref)throw new Error('A aba selecionada está vazia.');
 const range=XLSX.utils.decode_range(ref);if(range.e.c>299||range.e.r-headerRow+1>MAX_LI_ROWS)throw new Error('Importe até 10.000 linhas e 300 colunas por arquivo. Divida a planilha em partes menores.');
 const table=XLSX.utils.sheet_to_json<string[]>(sheet,{header:1,raw:false,defval:'',blankrows:true,range:0});
 const headings=table[headerRow-1];if(!headings?.some(x=>String(x).trim()))throw new Error('A linha do cabeçalho está vazia.');
 const width=Math.max(headings.length,...table.slice(headerRow).map(x=>x.length));
 const headers=Array.from({length:width},(_,i)=>String(headings[i]||'').trim()||`Coluna ${XLSX.utils.encode_col(i)}`);
 const rows=table.slice(headerRow).map((values,i)=>({rowNumber:headerRow+i+1,values:Array.from({length:width},(_,j)=>String(values[j]??''))})).filter(x=>x.values.some(v=>v.trim()));
 if(!rows.length)throw new Error('Não há dados após o cabeçalho selecionado.');
 return {sheets:book.SheetNames,sheet:name,headers,rows};
}
if(typeof self!=='undefined'&&typeof document==='undefined')self.onmessage=(event:MessageEvent<{buffer:ArrayBuffer;sheet?:string;headerRow:number}>)=>{try{self.postMessage({data:readSheet(event.data.buffer,event.data.sheet,event.data.headerRow)});}catch(e){self.postMessage({error:(e as Error).message});}};
