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
  /* Las comisiones del cliente van por SERVICIO (booking / management /
     development / sello), no por «shows/canciones/merch»: con las claves
     inventadas, merchPctDe() y la liquidacion de editorial leian 0 %. */
  DB.clientes=[{id:"cli1",nombre:"ARTISTA UNO",nombreReal:"Uno",categoria:"artista",
    comisiones:{booking:15,management:20,development:0,sello:50},
    email:"a@b.c",activo:true,facturacion:"autonomo_irpf",ivaPct:21,irpfPct:15}];
  DB.promotores=[{id:"pro1",nombre:"Sala X",ciudad:"Madrid"}];
  /* Los nombres son los de TABLE_MAP, no los de la base: el caché es
     «cacheBruto» (no «cache») y la fecha de la canción «fechaLanzamiento».
     Escritos mal, la fila entra igual pero vale 0 € y sin fecha, asi que las
     vistas se pintaban con todo a cero y no se probaba ni una cuenta. Los
     gastos van con un cargo de cada tipo para que se ejecute el reparto
     artista / MALO de calcShow(). */
  DB.shows=[{id:"sh1",clienteId:"cli1",promotorId:"pro1",fecha:FECHA,ciudad:"Madrid",
    estado:"confirmado",cacheBruto:1000,moneda:"EUR",tipoCambio:1,ivaPct:21,
    gastos:[{concepto:"Vuelos",importe:120,cargo:"artista"},
            {concepto:"Hotel",importe:80,cargo:"malo"},
            {concepto:"Backline",importe:50,cargo:"promotor"}],
    comisionPct:15,baseComision:"bruto",retencionOrigen:0,
    cobro:{estado:"pendiente"},liq:{estado:"pendiente"}}];
  DB.canciones=[{id:"can1",titulo:"TEMA UNO",artistaId:"cli1",distribuidora:"ADA",
    isrc:"BK4DA2500001",fechaLanzamiento:FECHA,feeDistribucionPct:15,mgmtPct:20}];
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
  /* «consent» no existe: el campo es «consentimiento» (lo cazo la comprobacion
     de TABLE_MAP de arriba la primera vez que se ejecuto). Con la clave mala,
     esta fila contaba como SIN consentimiento en todo Mailing. */
  DB.suscriptores=[{id:"su1",email:"s@t.u",nombre:"Sus",etiquetas:[],consentimiento:true},
    {id:"su2",email:"con@sent.es",nombre:"Con Sent",ciudad:"Madrid",etiquetas:["repite"],
      consentimiento:true,baja:false},
    {id:"su3",email:"fuera@sent.es",nombre:"Excluido",ciudad:"Madrid",etiquetas:[],
      consentimiento:true,baja:false}];
  /* Una campaña con un excluido a mano: asi se ejecutan destinatariosCampana(),
     resumenFiltros() y la rama de la tabla que pinta el boton de quitar/meter. */
  DB.campanas=[{id:"camp1",nombre:"Bolo Madrid",asunto:"Volvemos",notas:"Aviso de fecha",
    filtros:{mailPlaza:"Madrid"},excluidos:["fuera@sent.es"],estado:"borrador",
    destinatariosN:1,creadoEn:FECHA+"T10:00:00Z"}];
  DB.medios=[{id:"me1",nombre:"Medio",tipo:"prensa"}];
  DB.contactos=DB.contactos||[];
  DB.soporteTickets=[{id:"tk1",asunto:"No veo mi liquidacion",cuerpo:"Falta la de agosto",
    estado:"abierto",prioridad:"normal",area:"bolsillo",autor:"u1",autorNombre:"Uno",
    autorRol:"artista",clienteId:"cli1",creadoEn:FECHA+"T10:00:00Z",actualizadoEn:FECHA+"T10:00:00Z",cerradoEn:""}];
  DB.soporteRespuestas=[{id:"sr1",ticketId:"tk1",texto:"Lo miramos",autor:"u2",
    autorNombre:"Equipo",creadoEn:FECHA+"T11:00:00Z"}];
  DB.eventos=[];DB.producciones=[];DB.temas=[];DB.mensajes=[];DB.tareas=[];

  /* ── Antes de pintar nada: que los nombres de campo EXISTAN ──
     Este arnes llena DB a mano, y un objeto de JavaScript se traga cualquier
     clave sin protestar. Asi es como «cache» (el campo es «cacheBruto») y
     «artista»/«fecha» (son «artistaId»/«fechaLanzamiento») estuvieron aqui sin
     que nadie se enterara: las vistas se pintaban con 0 € y sin fecha, y el OK
     salia verde igual. TABLE_MAP es la lista buena — la que usa la app para
     hablar con Postgres — asi que se comprueba contra ella.
     DB.merch se queda fuera a proposito: merch_ventas no pasa por TABLE_MAP,
     la mapea a mano loadRemote(). */
  var revisar=["clientes","promotores","shows","canciones","cancionParticipantes",
    "cancionIngresos","obras","obraParticipantes","obraIngresos","obraCanciones",
    "merchArticulos","suscriptores","campanas","medios","soporteTickets","soporteRespuestas",
    "temas","tareas","eventos","producciones","redesSnapshots","contexto","mensajes"];
  var sueltas=[];
  revisar.forEach(function(col){
    var map=TABLE_MAP[col];
    if(!map){sueltas.push(col+" no esta en TABLE_MAP");return}
    (DB[col]||[]).forEach(function(fila,i){
      Object.keys(fila).forEach(function(k){
        if(k.charAt(0)==="_")return;              // _editadoPor y compania
        if(!(k in map))sueltas.push(col+"["+i+"]."+k);
      });
    });
  });
  if(sueltas.length){
    print("  X  campos que la app NO lee (no estan en TABLE_MAP): "+sueltas.join(", "));
  }else{
    print("  ok  los datos de prueba usan los campos de TABLE_MAP");
  }

  var vistas=[["panel",typeof viewPanel!=="undefined"&&viewPanel],
    ["calendario",typeof viewCalendario!=="undefined"&&viewCalendario],
    ["shows",typeof viewShows!=="undefined"&&viewShows],
    ["producciones",typeof viewEventos!=="undefined"&&viewEventos],
    ["clientes",typeof viewClientes!=="undefined"&&viewClientes],
    ["contactos",typeof viewContactos!=="undefined"&&viewContactos],
    ["documentos",typeof viewDocumentos!=="undefined"&&viewDocumentos],
    ["mailing",typeof viewMailing!=="undefined"&&viewMailing],
    /* La vista cambia bastante con una campaña abierta (aviso, columna nueva en la
       tabla, otro boton en la cabecera), asi que se prueba como caso aparte. */
    ["mailing (campaña abierta)",typeof viewMailing!=="undefined"&&function(el,ta){
      var antes=filtro.campanaId;filtro.campanaId="camp1";
      try{viewMailing(el,ta)}finally{filtro.campanaId=antes}}],
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
