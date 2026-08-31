/* Stub de DOM minimo: solo lo que tocan las vistas al pintarse. */
function Nodo(tag){
  this.tagName=(tag||"div").toUpperCase(); this.children=[]; this.style={}; this.dataset={};
  this.classList={add(){},remove(){},toggle(){},contains(){return false}};
  this._html=""; this.value=""; this.textContent=""; this.checked=false; this.files=[];
  /* <select> mira .options y .selectedIndex antes de que exista ninguna <option> */
  this.options=[]; this.selectedIndex=-1; this.disabled=false; this.width=300; this.height=150;
}
Nodo.prototype.appendChild=function(n){this.children.push(n);return n};
Nodo.prototype.removeChild=function(){};
Nodo.prototype.remove=function(){};
Nodo.prototype.setAttribute=function(){};
Nodo.prototype.getAttribute=function(){return null};
Nodo.prototype.removeAttribute=function(){};
Nodo.prototype.addEventListener=function(){};
Nodo.prototype.removeEventListener=function(){};
Nodo.prototype.querySelector=function(){return new Nodo()};
Nodo.prototype.querySelectorAll=function(){return []};
Nodo.prototype.closest=function(){return null};
Nodo.prototype.getBoundingClientRect=function(){return {top:0,left:0,width:100,height:100,bottom:0,right:0}};
Nodo.prototype.focus=function(){};Nodo.prototype.blur=function(){};Nodo.prototype.click=function(){};
Nodo.prototype.scrollIntoView=function(){};
Nodo.prototype.insertAdjacentHTML=function(pos,h){this._html=(pos==="afterbegin")?h+this._html:this._html+h};
Nodo.prototype.insertAdjacentElement=function(){};
Nodo.prototype.insertBefore=function(n){return n};
Nodo.prototype.replaceChildren=function(){};
Nodo.prototype.contains=function(){return false};
Nodo.prototype.matches=function(){return false};
Nodo.prototype.animate=function(){return {finished:Promise.resolve(),cancel(){}}};
Nodo.prototype.getContext=function(){return {clearRect(){},fillRect(){},beginPath(){},moveTo(){},
  lineTo(){},stroke(){},fill(){},arc(){},closePath(){},save(){},restore(){},translate(){},
  scale(){},drawImage(){},fillText(){},measureText(){return {width:10}},createLinearGradient(){
  return {addColorStop(){}}},setLineDash(){}}};
Nodo.prototype.toDataURL=function(){return "data:,"};
Object.defineProperty(Nodo.prototype,"innerHTML",{get(){return this._html},set(v){this._html=String(v)}});
Object.defineProperty(Nodo.prototype,"outerHTML",{get(){return this._html}});
Object.defineProperty(Nodo.prototype,"firstChild",{get(){return this.children[0]||null}});
Object.defineProperty(Nodo.prototype,"parentNode",{get(){return null}});

var document={
  body:new Nodo("body"), documentElement:new Nodo("html"), head:new Nodo("head"),
  createElement(t){return new Nodo(t)}, createTextNode(){return new Nodo("text")},
  createDocumentFragment(){return new Nodo()},
  getElementById(){return new Nodo()}, querySelector(){return new Nodo()}, querySelectorAll(){return []},
  addEventListener(){}, removeEventListener(){}, execCommand(){}, 
  getSelection(){return {rangeCount:0,removeAllRanges(){},addRange(){},getRangeAt(){return{}}}},
  readyState:"complete", cookie:"", title:""
};
var localStorage={_d:{},getItem(k){return this._d[k]===undefined?null:this._d[k]},
  setItem(k,v){this._d[k]=String(v)},removeItem(k){delete this._d[k]},clear(){this._d={}}};
var sessionStorage=localStorage;
var location={href:"http://x/",hash:"",search:"",pathname:"/",reload(){},assign(){}};
var navigator={userAgent:"jsc",language:"es",clipboard:{writeText(){return Promise.resolve()}},onLine:true};
var window={document:document,localStorage:localStorage,sessionStorage:sessionStorage,
  location:location,navigator:navigator,innerWidth:1400,innerHeight:900,devicePixelRatio:1,
  addEventListener(){},removeEventListener(){},matchMedia(){return {matches:false,addListener(){},addEventListener(){}}},
  getComputedStyle(){return {getPropertyValue(){return ""}}},scrollTo(){},open(){return null},
  requestAnimationFrame(f){return 0},setTimeout(){return 0},setInterval(){return 0},
  clearTimeout(){},clearInterval(){},print(){},alert(){},confirm(){return false},prompt(){return null}};
var self=window, globalThis_=window;
function setTimeout(){return 0} function setInterval(){return 0}
function clearTimeout(){} function clearInterval(){}
function requestAnimationFrame(){return 0}
function fetch(){return Promise.resolve({ok:true,json(){return Promise.resolve({})},text(){return Promise.resolve("")}})}
function alert(){} function confirm(){return false} function prompt(){return null}
var supabase={createClient(){return null}};
var Chart=function(){this.destroy=function(){}};
var html2canvas=function(){return Promise.resolve(new Nodo())};

function Blob(p,o){this.size=0;this.type=(o&&o.type)||"";this._p=p}
Blob.prototype.text=function(){return Promise.resolve("")};
var URL={createObjectURL(){return "blob:x"},revokeObjectURL(){}};
function File(p,n,o){Blob.call(this,p,o);this.name=n}
function FileReader(){this.readAsText=function(){};this.readAsDataURL=function(){}}
function FormData(){this.append=function(){}}
function Image(){return new Nodo("img")}
function CustomEvent(t){this.type=t}
function Event(t){this.type=t}
function IntersectionObserver(){this.observe=function(){};this.disconnect=function(){}}
function ResizeObserver(){this.observe=function(){};this.disconnect=function(){}}
function MutationObserver(){this.observe=function(){};this.disconnect=function(){}}
function structuredClone(o){return JSON.parse(JSON.stringify(o))}
function btoa(s){return ""} function atob(s){return ""}
