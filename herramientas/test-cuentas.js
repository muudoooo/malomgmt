/* ── Las CUENTAS, con números fijos ──
   Por qué existe: la prueba de humo comprueba que las vistas se pintan sin
   reventar, y las de campañas que el filtrado de Mailing es el que toca. Pero
   hasta el 9 sep 2026 NINGUNA comprobaba un solo euro, y por eso pasó
   inadvertido que los datos de prueba escribían «cache» donde la app lee
   «cacheBruto»: todo valía 0 €, las vistas se pintaban igual y el OK salía
   verde. Un fallo en la cascada de dinero no deja la pantalla en blanco —
   deja un número mal, que es peor porque se factura.

   Cada caso trae los números a mano, calculados aparte. Si alguien cambia
   calcShow(), calcProd() o la cascada de merch, esto salta.

   Uso:  herramientas/test-cuentas.sh */
(function(){
  var malas=0, hechas=0;
  /* Los euros se comparan al céntimo: comparar en coma flotante a pelo hace
     fallar 1825.0000000000002 contra 1825. */
  function cmp(a,b){return Math.round(n(a)*100)===Math.round(n(b)*100)}
  function ok(que,dado,esperado){
    hechas++;
    if(cmp(dado,esperado)) print("  ok  "+que+" = "+esperado);
    else { malas++; print("  X   "+que+": esperaba "+esperado+" y sale "+dado) }
  }
  function base(){
    DB=blank(); DB.rol="admin"; DB.miRol="admin"; DB.miClienteId=null;
    /* Las comisiones del cliente van por SERVICIO (booking / management /
       development / sello): así las escribe la app y así las leen merchPctDe()
       y la liquidación de editorial. */
    DB.clientes=[
      {id:"cli_a",nombre:"CLIENTE A",categoria:"artista",activo:true,
       facturacion:"autonomo_irpf",ivaPct:21,irpfPct:15,
       comisiones:{booking:15,management:20,development:0,sello:50}},
      {id:"cli_b",nombre:"CLIENTE B",categoria:"artista",activo:true,
       facturacion:"sl",ivaPct:21,irpfPct:0,
       comisiones:{booking:20,management:20,development:0,sello:50}}];
    DB.promotores=[{id:"pro_a",nombre:"Sala A",categoria:"sala",ciudad:"Madrid"}];
  }

  /* ── 1. Show nacional, comisión sobre el bruto ──
     2.500 € de caché · 300 € de gastos a cargo del artista · 50 € a cargo de
     MALO · 200 € del promotor (no pintan nada en la cuenta del artista) ·
     15 % de comisión sobre el bruto · IVA 21 % al promotor.
       comisión  = 2.500 × 15 %            = 375
       neto      = 2.500 − 300 − 375       = 1.825
       margen    = 375 − 50                = 325
       factura al promotor = 2.500 + 525   = 3.025
       IVA del artista  = 1.825 × 21 %     = 383,25
       IRPF del artista = 1.825 × 15 %     = 273,75
       transferencia    = 1.825 + 383,25 − 273,75 = 1.934,50 */
  base();
  var s1={id:"s1",clienteId:"cli_a",promotorId:"pro_a",fecha:"2026-05-18",estado:"ejecutado",
    cacheBruto:2500,moneda:"EUR",tipoCambio:1,retencionOrigen:0,ivaPct:21,comisionPct:15,
    baseComision:"bruto",gastos:[{concepto:"Vuelos",importe:180,cargo:"artista"},
      {concepto:"Hotel",importe:120,cargo:"artista"},{concepto:"Backline",importe:200,cargo:"promotor"},
      {concepto:"Pasarela",importe:50,cargo:"malo"}]};
  DB.shows=[s1];
  var c1=calc(s1);
  print("· Show nacional, comisión sobre bruto");
  ok("bruto",c1.bruto,2500);
  ok("gastos del artista",c1.gArt,300);
  ok("gastos de MALO",c1.gMalo,50);
  ok("gastos del promotor",c1.gProm,200);
  ok("comisión",c1.comis,375);
  ok("neto del artista",c1.neto,1825);
  ok("margen de MALO",c1.margen,325);
  ok("IVA al promotor",c1.ivaProm,525);
  ok("factura al promotor",c1.facturaProm,3025);
  ok("IVA del artista",c1.ivaArt,383.25);
  ok("IRPF del artista",c1.irpfArt,273.75);
  ok("transferencia al artista",c1.transfer,1934.50);

  /* ── 2. Comisión sobre el NETO (no sobre el bruto) ──
     1.800 € · 90 € de gastos del artista · 35 € de MALO · 20 % sobre el neto.
       base de comisión = 1.800 − 90        = 1.710
       comisión         = 1.710 × 20 %      = 342
       neto             = 1.800 − 90 − 342  = 1.368
       cliente SL: IVA 21 %, IRPF 0 → transferencia = 1.368 × 1,21 = 1.655,28 */
  base();
  var s2={id:"s2",clienteId:"cli_b",promotorId:"pro_a",fecha:"2026-07-09",estado:"ejecutado",
    cacheBruto:1800,moneda:"EUR",tipoCambio:1,retencionOrigen:0,ivaPct:21,comisionPct:20,
    baseComision:"neto",gastos:[{concepto:"Tren",importe:90,cargo:"artista"},
      {concepto:"Pasarela",importe:35,cargo:"malo"}]};
  DB.shows=[s2];
  var c2=calc(s2);
  print("· Comisión sobre el neto");
  ok("base de comisión",c2.baseCom,1710);
  ok("comisión",c2.comis,342);
  ok("neto del artista",c2.neto,1368);
  ok("margen de MALO",c2.margen,307);
  ok("IRPF del artista (SL, sin retención)",c2.irpfArt,0);
  ok("transferencia al artista",c2.transfer,1655.28);

  /* ── 3. Fecha fuera de España: retención en origen ──
     1.200 € con 25 % retenido en origen y 10 % de comisión sobre el bruto.
       retención = 300 · recibido = 900 · comisión = 120 · neto = 780
     Ojo: la comisión se calcula sobre el BRUTO (1.200), no sobre lo recibido. */
  base();
  var s3={id:"s3",clienteId:"cli_a",promotorId:"pro_a",fecha:"2026-08-22",estado:"ejecutado",
    cacheBruto:1200,moneda:"EUR",tipoCambio:1,retencionOrigen:25,ivaPct:0,comisionPct:10,
    baseComision:"bruto",gastos:[]};
  DB.shows=[s3];
  var c3=calc(s3);
  print("· Retención en origen del 25 %");
  ok("retenido en origen",c3.reten,300);
  ok("recibido",c3.recib,900);
  ok("comisión (sobre el bruto)",c3.comis,120);
  ok("neto del artista",c3.neto,780);

  /* ── 4. Caché en otra moneda ──
     2.500 de una divisa a 0,92 → 2.300 € de bruto, y 10 % de comisión = 230. */
  base();
  var s4={id:"s4",clienteId:"cli_a",promotorId:"pro_a",fecha:"2026-09-01",estado:"confirmado",
    cacheBruto:2500,moneda:"USD",tipoCambio:0.92,retencionOrigen:0,ivaPct:0,comisionPct:10,
    baseComision:"bruto",gastos:[]};
  DB.shows=[s4];
  var c4=calc(s4);
  print("· Caché en divisa (tipo de cambio 0,92)");
  ok("bruto en euros",c4.bruto,2300);
  ok("comisión",c4.comis,230);
  ok("neto del artista",c4.neto,2070);

  /* ── 5. Pendiente de liquidar ──
     Dos fechas cobradas: una ya liquidada y otra no. Solo la segunda es deuda
     con el artista, y vale su transferencia (1.655,28 del caso 2). */
  base();
  DB.shows=[
    Object.assign({},s2,{id:"sA",cobro:{estado:"cobrado"},liq:{estado:"liquidado"}}),
    Object.assign({},s2,{id:"sB",cobro:{estado:"cobrado"},liq:{estado:"pendiente"}})];
  var pend=pendienteDeLiquidar("cli_b");
  print("· Pendiente de liquidar");
  ok("fechas pendientes",pend.length,1);
  ok("dinero pendiente",pend.reduce(function(t,s){return t+calc(s).transfer},0),1655.28);

  /* ── 6. Producción propia: P&L ──
     392 entradas a 15 € + 96 a 20 € = 7.800 € de taquilla con IVA (10 %).
       taquilla neta = 7.800 / 1,10          = 7.090,91
       ingresos = 7.090,91 + 900 (barra) + 1.000 (sponsor) = 8.990,91
       costes   = 1.800 (cachés) + 380 (viajes) + 250 (crew) + 3.050 (otros) = 5.480
       beneficio = 3.510,91 · precio medio = 7.090,91 / 488 = 14,53 */
  base();
  var p={id:"p1",nombre:"NOCHE",fecha:"2026-07-14",ciudad:"Madrid",aforo:600,ivaEntrada:10,modoFee:false,
    entradas:[{tipo:"Anticipada",precio:15,cupo:400,vendidas:392},{tipo:"Taquilla",precio:20,cupo:200,vendidas:96}],
    otrosIngresos:[{concepto:"Barra",importe:900}],sponsorAportacion:1000,
    lineup:[{clienteId:"cli_a",cache:1200,alojImporte:180,transImporte:120},
            {clienteId:"cli_b",cache:600,alojImporte:0,transImporte:80}],
    crew:[{nombre:"Sonido",cache:250,alojImporte:0,transImporte:0}],
    costes:[{concepto:"Sala",importe:1500},{concepto:"Técnica",importe:800},
            {concepto:"Publicidad",importe:450},{concepto:"Seguridad",importe:300}]};
  DB.producciones=[p];
  var cp=calcProd(p);
  print("· Producción propia");
  ok("entradas vendidas",cp.vendidas,488);
  ok("taquilla con IVA",cp.taquillaPVP,7800);
  ok("taquilla neta",cp.taquillaNeta,7090.91);
  ok("ingresos",cp.ingresos,8990.91);
  ok("cachés del line-up",cp.cacheArtistas,1800);
  ok("viajes del line-up",cp.viajesLineup,380);
  ok("coste del crew",cp.costeCrew,250);
  ok("costes",cp.costes,5480);
  ok("beneficio",cp.beneficio,3510.91);
  ok("precio medio por entrada",cp.precioMedio,14.53);

  /* ── 7. Cascada del merch ──
     Dos camisetas a 25 € con IVA (50 € y 8,68 € de impuesto) y 7,50 € de coste
     por unidad, producidas por el artista:
       base    = 50 − 8,68        = 41,32
       coste   = 2 × 7,50         = 15
       margen  = 41,32 − 15       = 26,32
       comisión = 26,32 × 20 %    = 5,26   ← el 20 % es comisiones.management
       neto al artista            = 21,06
     La comisión distinta de 0 es el aserto que importa: si alguien vuelve a
     escribir esa clave con otro nombre, merchPctDe() devuelve 0 y el artista
     se lleva el margen entero sin que nada lo diga. */
  base();
  DB.merchArticulos=[{titulo:"CAMISETA",clienteId:"cli_a",tipo:"textil",costeUnitario:7.5,
    quienPago:"artista",unidadesProducidas:100,ivaPct:21,facturaUrl:""}];
  DB.merch=[{id:"mv1",tienda:"demo",numero:"#1",fecha:"2026-08-04T12:00:00Z",email:"c@d.e",
    comprador:"Comprador",total:50,moneda:"EUR",estadoPago:"PAID",ivaIncluido:true,totalImpuestos:8.68,
    items:[{titulo:"CAMISETA",cantidad:2,importe:50,impuesto:8.68}]}];
  var l=merchLineas()[0]||{};
  print("· Cascada del merch");
  ok("base sin IVA",l.importe,41.32);
  ok("coste de producción",l.coste,15);
  ok("margen",l.margen,26.32);
  ok("comisión de MALO",l.comision,5.26);
  ok("neto al artista",l.neto,21.06);

  print("");
  print(malas? "  X  "+malas+" de "+hechas+" cuentas NO cuadran"
             : "  TODO OK · "+hechas+" cuentas cuadran al céntimo");
})();
