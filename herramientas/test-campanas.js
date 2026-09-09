/* ── Campañas de Mailing: comprobaciones de que hace lo correcto ──
   El humo solo prueba que las vistas no revientan. Esto prueba el CÁLCULO, que
   es donde duele: a cuánta gente le va una campaña.

   Lo que se vigila sobre todo es que nadie sin consentimiento entre en una
   campaña, ni con los filtros abiertos ni por descuido. Eso no es un detalle
   de producto, es la parte con multa.

   Uso:  herramientas/test-campanas.sh
*/
DB=blank(); DB.rol="admin";
DB.suscriptores=[
  {id:"su1",email:"sin@consent.es",nombre:"Sin",ciudad:"Madrid",etiquetas:[],consentimiento:false,baja:false},
  {id:"su2",email:"con@sent.es",nombre:"Con",ciudad:"Madrid",etiquetas:["repite"],consentimiento:true,baja:false},
  {id:"su3",email:"fuera@sent.es",nombre:"Fuera",ciudad:"Madrid",etiquetas:[],consentimiento:true,baja:false},
  {id:"su4",email:"otra@ciudad.es",nombre:"Otra",ciudad:"Bilbao",etiquetas:[],consentimiento:true,baja:false},
  {id:"su5",email:"baja@sent.es",nombre:"Baja",ciudad:"Madrid",etiquetas:[],consentimiento:true,baja:true}];
DB.campanas=[{id:"camp1",nombre:"Bolo Madrid",filtros:{mailPlaza:"Madrid"},
  excluidos:["fuera@sent.es"],estado:"borrador"}];
var fallos=0;
function eq(a,b,q){ if(a!==b){print("  X  "+q+" -> esperaba "+b+", dio "+a);fallos++} else print("  ok  "+q+" = "+a); }

// 1 · destinatarios: Madrid con consentimiento, menos el excluido, menos la baja
eq(destinatariosCampana(DB.campanas[0]).length,1,"destinatarios de la campana");
eq(destinatariosCampana(DB.campanas[0])[0].email,"con@sent.es","y es el que toca");

// 2 · susDeFiltros no debe dejar el estado tocado
filtro.mailPlaza="Bilbao"; filtro.q="hola";
susDeFiltros({mailPlaza:"Madrid"});
eq(filtro.mailPlaza,"Bilbao","filtro.mailPlaza restaurado");
eq(filtro.q,"hola","filtro.q restaurado");
filtro.mailPlaza=""; filtro.q="";

// 3 · filtrosActuales recoge solo lo puesto
filtro.mailPlaza="Madrid"; filtro.mailSoloConsent=true;
var f=filtrosActuales();
eq(JSON.stringify(f),JSON.stringify({mailPlaza:"Madrid",mailSoloConsent:true}),"filtrosActuales");
eq(resumenFiltros(f),"Madrid · solo con consentimiento","resumenFiltros");
filtro.mailPlaza=""; filtro.mailSoloConsent=false;

// 4 · sin filtros = toda la lista
eq(resumenFiltros({}),"toda la lista","resumen sin filtros");

// 5 · quitar y volver a meter a alguien (solo con la campana abierta, que es
//     cuando existe el boton en la tabla)
toast=function(){}; touch=function(){}; render=function(){};
eq(!!campanaAbierta(),false,"sin campanaId no hay campana abierta");
filtro.campanaId="camp1";
eq(!!campanaAbierta(),true,"con campanaId si la hay");
toggleExcluido("con@sent.es");
eq(DB.campanas[0].destinatariosN,0,"destinatariosN se recalcula al quitar");
eq(destinatariosCampana(DB.campanas[0]).length,0,"tras quitar al unico");
toggleExcluido("con@sent.es");
eq(destinatariosCampana(DB.campanas[0]).length,1,"tras volver a meterlo");

// 6 · una campana sin filtros no puede colar a quien no tiene consentimiento
eq(destinatariosCampana({filtros:{},excluidos:[]}).length,3,"sin filtros solo los 3 con consent");

print(fallos?("\n  FALLOS: "+fallos):"\n  TODO OK");
