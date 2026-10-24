import {
  MigrationTimeline,
  CountryRanking,
  AgeDemographics,
  GlobalImpactStats,
  ScalabilityMarket,
  ElderlyVulnerability,
  DomesticAccidentStats,
  EmergencyResponseTime,
  RegionalVulnerability,
  KPIItem,
  FlowStep,
  ReferenceItem,
  ProgressBarItem
} from "./types.js";

export const MIGRATION_DATA: MigrationTimeline = {
  labels: [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024],
  total: [0.695, 1.0, 1.6, 2.6, 3.93, 5.4, 6.0, 7.1, 7.7, 7.89],
  americas: [0.42, 0.65, 1.1, 2.1, 3.4, 4.7, 5.4, 6.4, 6.9, 7.1]
};

export const COUNTRIES_DATA: CountryRanking = {
  labels: [
    "Colombia",
    "Perú",
    "EE.UU.",
    "Brasil",
    "España",
    "Chile",
    "Ecuador",
    "Argentina",
    "Rep. Dom.",
    "México"
  ],
  values: [2850000, 1550000, 940000, 670000, 600000, 595000, 445000, 174000, 125000, 107000]
};

export const AGES_DATA: AgeDemographics = {
  labels: ["15–24 años", "25–34 años", "35–44 años", "45–54 años", "55+ años", "0–14 años"],
  values: [22, 31, 20, 13, 7, 7],
  colors: ["#818cf8", "#6366f1", "#34d399", "#22c55e", "#fbbf24", "#94a3b8"]
};

export const GLOBAL_ELDERLY_DATA: GlobalImpactStats = {
  labels: [
    "Venezuela 🇻🇪",
    "Ucrania 🇺🇦",
    "Moldavia 🇲🇩",
    "Cuba 🇨🇺",
    "Triángulo Norte 🇸🇻🇬🇹",
    "Siria 🇸🇾",
    "Filipinas 🇵🇭",
    "Colombia 🇨🇴"
  ],
  pctSolos: [35.0, 34.0, 32.0, 29.0, 28.0, 27.0, 24.0, 21.0],
  colors: ["#818cf8", "#6366f1", "#a78bfa", "#f87171", "#fb923c", "#fbbf24", "#34d399", "#94a3b8"]
};

export const ESCALABILIDAD_DATA: ScalabilityMarket = {
  labels: [
    "Venezuela (Validación)",
    "Resto Sudamérica",
    "Centroamérica / Caribe",
    "Europa del Este",
    "Medio Oriente / Asia"
  ],
  millones: [0.5, 4.2, 5.8, 8.5, 12.0],
  colors: ["#818cf8", "#34d399", "#fbbf24", "#f87171", "#a78bfa"]
};

export const MAYORES_DATA: ElderlyVulnerability = {
  labels: [
    "Con hijos en exterior",
    "Dependen del exterior (economía)",
    "Hogares solo con mayores",
    "Sin medicamentos regulares",
    "Perdieron familiares por diáspora"
  ],
  values: [65.6, 62.0, 35.0, 45.3, 75.0],
  colors: ["#818cf8", "#a78bfa", "#f87171", "#fb923c", "#fbbf24"]
};

export const ACCIDENTS_DATA: DomesticAccidentStats = {
  labels: [
    "Caídas en el hogar",
    "Intoxicaciones",
    "Quemaduras",
    "Cardíacos sin asistencia",
    "Incendios",
    "Otros"
  ],
  values: [42, 17, 12, 16, 8, 5],
  colors: ["#f87171", "#fb923c", "#fbbf24", "#a78bfa", "#f472b6", "#94a3b8"]
};

export const RESPUESTA_DATA: EmergencyResponseTime = {
  labels: ["Sin sistema\nde alerta", "Con llamada\nmanual", "Con En Casa"],
  values: [47, 22, 2],
  colors: ["#ef4444", "#f97316", "#22c55e"]
};

export const ESTADOS_DATA: RegionalVulnerability = {
  labels: ["Zulia", "Miranda", "Carabobo", "Bolívar", "Lara", "Mérida", "Anzoátegui", "Barinas", "Táchira", "Aragua"],
  vulnIdx: [88, 82, 79, 74, 71, 68, 65, 63, 61, 58],
  hijosExt: [72, 68, 65, 58, 54, 61, 49, 45, 57, 51]
};

export const KPI_MAIN: KPIItem[] = [
  { icon: "🌍", val: "7.89 M", label: "Venezolanos en el exterior", sub: "Récord histórico · ACNUR 2024", color: "#818cf8" },
  { icon: "👴", val: "3.2 M", label: "Adultos mayores (60+) en VE", sub: "12–12.7% de la población · CEPAL", color: "#a78bfa" },
  { icon: "🏠", val: "400 K+", label: "Mayores solos por emigración", sub: "Convite AC / ENCOVI 2023", color: "#f87171" },
  { icon: "🌐", val: "31 M+", label: "Mayores solos en el mundo", sub: "Diásporas juveniles · HelpAge/OIM", color: "#34d399" },
  { icon: "⏱️", val: "47 min", label: "Sin alerta de emergencia", sub: "Tiempo promedio sin En Casa", color: "#fbbf24" },
  { icon: "📱", val: "53 %", label: "Mayores con tecnología asistiva", sub: "U.S. News & World Report 2023", color: "#60a5fa" }
];

export const KPI_MAYORES: KPIItem[] = [
  { icon: "👴", val: "3.2 M", label: "Adultos mayores (60+)", sub: "CEPAL/CELADE 2023", color: "#818cf8" },
  { icon: "🏠", val: "400 K+", label: "Viven solos · por emigración", sub: "Convite AC / ENCOVI 2023", color: "#f87171" },
  { icon: "👨‍👩‍👦", val: "62 %", label: "Dependen económicamente", sub: "De familiares en el exterior", color: "#fbbf24" },
  { icon: "💀", val: "1 de 3", label: "Sufrirá una caída este año", sub: "OMS — adultos 65+ · 2022", color: "#f87171" },
  { icon: "⏳", val: "1 de 5", label: "Queda >1h en el suelo solo", sub: "NIH — riesgo de muerte x2", color: "#a78bfa" },
  { icon: "📞", val: "75 %+", label: "Perdieron familiares cercanos", sub: "ENCOVI 2023 — por diáspora", color: "#34d399" }
];

export const FLOW_STEPS: FlowStep[] = [
  {
    fase: "Fase 1 · Casa",
    icon: "🎙️",
    title: "Oído Continuo & Sensores",
    desc: "Micrófono crudo sin supresión de ruido (para no filtrar golpes) + acelerómetro para vibración de piso + sensor de proximidad y enchufe continuo.",
    badge: "Hardware Local"
  },
  {
    fase: "Fase 2 · IA",
    icon: "🧠",
    title: "YAMNet On-Device",
    desc: "Compuerta de dB adaptativa contra ruido de fondo. YAMNet (TFLite) clasifica 2 veces/seg en buffer de 5 s en RAM. Audio 100% privado en memoria.",
    badge: "Edge Computing"
  },
  {
    fase: "Fase 3 · Filtro",
    icon: "🔔",
    title: "Alarma Local de 60 s",
    desc: "Tono de 520 Hz + vibración + destello en pantalla. Deslizar riel ancho «Estoy bien» o proximidad cancela. Botón «Necesito ayuda» escala ya.",
    badge: "Zero Falsas Alarmas"
  },
  {
    fase: "Fase 4 · Alerta",
    icon: "📡",
    title: "Escalamiento en Serie",
    desc: "Si nadie apaga en 60 s: T1 (10 s) POST a Supabase. Si falla o timeout: T2 (25 s) llamada telefónica GSM local a vecino. T3: SMS de respaldo.",
    badge: "Multi-Canal"
  },
  {
    fase: "Fase 5 · Familia",
    icon: "📲",
    title: "Telegram & Web PWA",
    desc: "La familia recibe aviso en Telegram y abre PWA con token/QR sin login. Pantalla roja con botón para llamar a Carmen o al vecino.",
    badge: "Transfronterizo"
  },
  {
    fase: "Fase 6 · Rutina",
    icon: "💓",
    title: "Latido & Cuidado Diario",
    desc: "Monitoreo de latido («sin señal desde las XX:XX»). Recordatorio diario de pastillas y botón «Estoy bien hoy» para acompañar todos los días.",
    badge: "Monitoreo 24/7"
  }
];

export const SYSTEM_LAYERS = [
  {
    title: "📱 1. Teléfono de la Casa (Flutter en Android)",
    items: [
      "Funciona en teléfonos viejos dedicados, conectados permanentemente a corriente.",
      "Buffer circular de audio de 5 segundos en memoria RAM: el audio nunca se graba en disco ni sale del equipo.",
      "Clasificador YAMNet optimizado con TensorFlow Lite: reduce 521 clases a 6 tipos esenciales (alarma, vidrio, golpe, grito, TV, rutina).",
      "Interfaz para el adulto mayor: pantalla de reposo con reloj, botón de pánico, 'Huele a gas', 'Me siento mal' y confirmación de pastillas."
    ]
  },
  {
    title: "⚡ 2. Escalamiento Inteligente & Red Local",
    items: [
      "Tiempo de gracia de 60 segundos con tono de 520 Hz en onda cuadrada (óptimo para personas mayores).",
      "Escalamiento secuencial automático: Canal T1 HTTP Supabase (10 s) → Canal T2 Llamada local GSM a vecino (25 s) → Canal T3 SMS de respaldo.",
      "Detección de apagones eléctricos mediante el estado de alimentación (`BatteryManager.EXTRA_PLUGGED`).",
      "Perfil de salud dinámico: un apagón es 🔴 Rojo urgente si la persona usa concentrador de oxígeno, o 🟡 Amarillo si no tiene equipo crítico."
    ]
  },
  {
    title: "🌍 3. Panel de la Familia en el Exterior (Next.js PWA & Telegram)",
    items: [
      "Sin fricción: no requiere instalar apps pesadas; abre mediante enlace con token o escaneo de código QR.",
      "Canal prioritario por Bot de Telegram para entrega inmediata con sonido de alta prioridad.",
      "Pantalla de 'Alerta Urgente' con protocolo de acción: 'Llamar a Carmen', 'Llamar al vecino de confianza' y botón 'Ya hablé con ella'.",
      "Monitor de latido en tiempo real: muestra 'Todo bien' o notifica 'Sin señal desde las XX:XX' si se corta la conexión o se apaga el equipo."
    ]
  }
];

export const PROGRESS_ITEMS: ProgressBarItem[] = [
  { label: "Con hijos en el exterior", val: 65.6, color: "#818cf8" },
  { label: "Dependen del exterior", val: 62.0, color: "#f87171" },
  { label: "Perdieron familiares", val: 75.0, color: "#fbbf24" },
  { label: "Sin medicamentos", val: 45.3, color: "#fb923c" },
  { label: "Hogares solo con mayores", val: 35.0, color: "#a78bfa" }
];

export const REFERENCES: ReferenceItem[] = [
  {
    icon: "🌐",
    title: "ACNUR/UNHCR — R4V Plataforma Regional",
    year: "2024",
    desc: "7.89M venezolanos fuera del país. ~370K refugiados; +1.4M en proceso de asilo. 85% permanece en América Latina.",
    url: "https://www.r4v.info/es/situations/platform"
  },
  {
    icon: "🌐",
    title: "OIM — Displacement Tracking Matrix (DTM)",
    year: "2023",
    desc: "66% de los adultos migrantes venezolanos tienen 18–34 años. Edad promedio del migrante: ~34 años.",
    url: "https://www.iom.int/displacement-tracking-matrix"
  },
  {
    icon: "🌐",
    title: "HelpAge International & OIM — 'Left Behind' Older Persons",
    year: "2023–2024",
    desc: "Estudios sobre el síndrome del nido vacío migratorio: millones de adultos mayores quedan sin cuidadores en Latinoamérica, Europa del Este y Asia por el éxodo de generaciones productivas.",
    url: "https://www.helpage.org/what-we-do/migration/"
  },
  {
    icon: "📊",
    title: "CEPAL/CELADE — Envejecimiento en América Latina",
    year: "2023",
    desc: "12–12.7% de la población venezolana tiene 60+. 65 dependientes por cada 100 en edad activa. Proyección 2050: 21%.",
    url: "https://www.cepal.org/es/temas/envejecimiento"
  },
  {
    icon: "🏥",
    title: "OMS/WHO — Fact Sheet on Falls",
    year: "2022",
    desc: "842.000 muertes/año por caídas. 2ª causa de muerte por lesión. 1 de cada 3 adultos 65+ cae cada año.",
    url: "https://www.who.int/news-room/fact-sheets/detail/falls"
  },
  {
    icon: "🏥",
    title: "NIH / CDC — Elder Falls Prevention",
    year: "2023",
    desc: "1 de cada 5 adultos mayores que cae permanece en el suelo >1 hora si vive solo. Riesgo de muerte se duplica.",
    url: "https://www.cdc.gov/falls/data/index.html"
  },
  {
    icon: "📋",
    title: "Convite AC — Adultos Mayores en Venezuela",
    year: "2023",
    desc: "300.000–500.000 mayores viven completamente solos. 62% depende económicamente del exterior. 75%+ perdió familiares.",
    url: "https://www.conviteac.org"
  },
  {
    icon: "📋",
    title: "ENCOVI — Encuesta Condiciones de Vida (UCAB)",
    year: "2023",
    desc: "~35% de hogares integrados solo por adultos mayores. 51 mayores por cada 100 menores — inversión demográfica.",
    url: "https://www.ucab.edu.ve/investigacion/encovi/"
  },
  {
    icon: "📱",
    title: "AARP — Technology Research Older Adults",
    year: "2023",
    desc: "53% de adultos 55+ usan tecnología asistiva. 25% apps médicas. 17% sistemas de detección de caídas.",
    url: "https://www.aarp.org/research/topics/technology"
  },
  {
    icon: "📰",
    title: "INE Venezuela — Proyecciones de Población",
    year: "2022",
    desc: "Distribución demográfica de adultos mayores por estado. Base para estimaciones de vulnerabilidad regional.",
    url: "https://www.ine.gov.ve"
  }
];
