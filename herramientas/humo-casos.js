/* ── Los casos ──
   Se llena DB con una fila de cada cosa (no vale dejarlo vacio: casi todas las
   vistas cortan antes con un «no hay nada que enseñar» y no se prueba nada) y
   se llama a cada vista. Lo que se busca no es que el HTML este bien, es que
   la funcion no reviente. */
(function(){
  var hoy=new Date(), MES=hoy.getFullYear()+"-"+String(hoy.getMonth()+1).padStart(2,"0");
  var FECHA=MES+"-15";

  DB=blank();
  DB.miClienteId=null; DB.rol="admin";
  DB.clientes=[{id:"cli1",nombre:"ARTISTA UNO",nombreReal:"Uno",categoria:"artista",
    comisiones:{shows:15,canciones:20,merch:20},email:"a@b.c",activo:true}];
  DB.promotores=[{id:"pro1",nombre:"Sala X",ciudad:"Madrid"}];
  DB.shows=[{id:"sh1",clienteId:"cli1",promotorId:"pro1",fecha:FECHA,ciudad:"Madrid",
    estado:"confirmado",cache:1000,ivaPct:21,gastos:[],comisionPct:15,retencionOrigen:0}];
  DB.canciones=[{id:"can1",titulo:"TEMA UNO",artista:"ARTISTA UNO",distribuidora:"ADA",
    isrc:"BK4DA2500001",fecha:FECHA,release:"Single"}];
  DB.cancionParticipantes=[{id:"cp1",cancionId:"can1",clienteId:"cli1",pct:100}];
  DB.cancionIngresos=[{id:"ci1",cancionId:"can1",mes:MES,bruto:100}];
  DB.obras=[{id:"ob1",workCode:"DWD001",titulo:"TEMA UNO",editorial:"UMPG"}];
  DB.obraParticipantes=[{id:"op1",obraId:"ob1",clienteId:"cli1",nombre:"Uno",
    capacidad:"CA",contPct:50,mecanicoPct:37.5,ejecucionPct:37.5}];
  DB.obraIngresos=[{id:"oi1",obraId:"ob1",clienteId:"cli1",fuente:"UMPG",periodo:"2026-01",
    devengoDesde:"202504",devengoHasta:"202506",tipoUso:"Online Lyrics",dsp:"APPLE MUSIC",
    territorio:"ES",unidades:0,importeBruto:10,importeNeto:7.5}];
  DB.obraCanciones=[{obraId:"ob1",cancionId:"can1",confianza:"manual"}];
  DB.merchArticulos=[{titulo:"CAMISETA",clienteId:"cli1",tipo:"textil",costeUnitario:8,
    quienPago:"artista",unidadesProducidas:100,ivaPct:21,facturaUrl:""}];
  DB.merch=[{id:"mv1",tienda:"malo",numero:"#1001",fecha:FECHA+"T12:00:00Z",email:"c@d.e",
    comprador:"Comprador",total:31,moneda:"EUR",estadoPago:"PAID",ivaIncluido:true,
    totalImpuestos:5.38,items:[{titulo:"CAMISETA",cantidad:1,importe:25,impuesto:4.34}]}];
  DB.suscriptores=[{id:"su1",email:"s@t.u",nombre:"Sus",etiquetas:[],consent:true}];
  DB.medios=[{id:"me1",nombre:"Medio",tipo:"prensa"}];
  DB.contactos=DB.contactos||[];
  DB.soporteTickets=[{id:"tk1",asunto:"No veo mi liquidacion",cuerpo:"Falta la de agosto",
    estado:"abierto",prioridad:"normal",area:"bolsillo",autor:"u1",autorNombre:"Uno",
    autorRol:"artista",clienteId:"cli1",creadoEn:FECHA+"T10:00:00Z",actualizadoEn:FECHA+"T10:00:00Z",cerradoEn:""}];
  DB.soporteRespuestas=[{id:"sr1",ticketId:"tk1",texto:"Lo miramos",autor:"u2",
    autorNombre:"Equipo",creadoEn:FECHA+"T11:00:00Z"}];
  DB.eventos=[];DB.producciones=[];DB.temas=[];DB.mensajes=[];DB.tareas=[];

  var vistas=[["panel",typeof viewPanel!=="undefined"&&viewPanel],
    ["calendario",typeof viewCalendario!=="undefined"&&viewCalendario],
    ["shows",typeof viewShows!=="undefined"&&viewShows],
    ["producciones",typeof viewEventos!=="undefined"&&viewEventos],
    ["clientes",typeof viewClientes!=="undefined"&&viewClientes],
    ["contactos",typeof viewContactos!=="undefined"&&viewContactos],
    ["documentos",typeof viewDocumentos!=="undefined"&&viewDocumentos],
    ["mailing",typeof viewMailing!=="undefined"&&viewMailing],
    ["medios",typeof viewMedios!=="undefined"&&viewMedios],
    ["mapa",typeof viewMapa!=="undefined"&&viewMapa],
    ["canciones",typeof viewCanciones!=="undefined"&&viewCanciones],
    ["editorial",typeof viewEditorial!=="undefined"&&viewEditorial],
    ["bolsillo",typeof viewBolsillo!=="undefined"&&viewBolsillo],
    ["merch",typeof viewMerch!=="undefined"&&viewMerch],
    ["redes",typeof viewRedes!=="undefined"&&viewRedes],
    ["equipo",typeof viewEquipo!=="undefined"&&viewEquipo],
    ["capturas",typeof viewCapturas!=="undefined"&&viewCapturas],
    ["generadores",typeof viewGeneradores!=="undefined"&&viewGeneradores],
    ["soporte",typeof viewSoporte!=="undefined"&&viewSoporte],
    ["datos",typeof viewDatos!=="undefined"&&viewDatos]];

  var malas=0, hechas=0;
  /* Cada vista, en modo oficina y con cada pestaña interna que tenga. */
  var pestanas={editorial:["alertas","catalogo","ingresos","liquidacion"],
                canciones:["galeria","lista"]};
  vistas.forEach(function(par){
    var nom=par[0], fn=par[1];
    if(!fn){print("  ?  "+nom+" · no existe esa funcion");return}
    var subs=pestanas[nom]||[null];
    subs.forEach(function(sub){
      if(sub&&nom==="editorial")filtro.edVista=sub;
      if(sub&&nom==="canciones")filtro.cancionVista=sub;
      hechas++;
      try{ fn(new Nodo(),new Nodo()) }
      catch(e){ malas++; print("  X  "+nom+(sub?" · "+sub:"")+"  →  "+e.name+": "+e.message) }
    });
  });

  /* Y ahora el portal del artista, que recorre otras ramas del codigo. */
  DB.rol="artista"; DB.miClienteId="cli1";
  [["inicio",typeof viewInicioPortal!=="undefined"&&viewInicioPortal],
   ["bolsillo",typeof viewBolsillo!=="undefined"&&viewBolsillo],
   ["merch",typeof viewMerch!=="undefined"&&viewMerch],
   ["canciones",typeof viewCanciones!=="undefined"&&viewCanciones],
   ["editorial",typeof viewEditorial!=="undefined"&&viewEditorial]].forEach(function(par){
    if(!par[1])return; hechas++;
    try{ par[1](new Nodo(),new Nodo()) }
    catch(e){ malas++; print("  X  portal/"+par[0]+"  →  "+e.name+": "+e.message) }
  });

  print(malas? "  X  "+malas+" de "+hechas+" vistas revientan al ejecutarse"
             : "  OK  "+hechas+" vistas se ejecutan sin reventar");
})();
