import { readFile, access } from 'node:fs/promises';
import { products, cases, services, articles } from '../src/data.js';
const images=new Set();
for(const item of [...products,...cases,...services,...articles]){
  if(item.image) images.add(item.image);
  for(const image of item.gallery||[]) images.add(image);
}
const source=await readFile(new URL('../src/main.js',import.meta.url),'utf8');
for(const match of source.matchAll(/['"](\d{3}-\d)['"]/g))images.add(match[1]);
const missing=[];
for(const name of images){try{await access(new URL(`../public/images/${name}.webp`,import.meta.url));}catch{missing.push(name);}}
if(missing.length)throw new Error(`Missing images: ${missing.join(', ')}`);
for(const item of [...products,...cases]){
 if(!/^\d+$/.test(item.source))throw new Error(`Missing original publication for ${item.id}`);
}
for(const group of [products,cases,services,articles]){
 if(new Set(group.map(x=>x.id)).size!==group.length)throw new Error('Duplicate route id');
}
console.log(`Verified ${images.size} local images, original publications, and route ids.`);
