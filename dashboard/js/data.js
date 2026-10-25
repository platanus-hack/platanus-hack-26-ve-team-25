export const MIGRATION_DATA = {
    labels: [2015, 2017, 2019, 2020, 2021, 2022, 2023, 2024],
    total: [0.695, 1.6, 3.93, 5.4, 6.0, 7.1, 7.7, 7.89],
    americas: [0.42, 1.1, 3.4, 4.7, 5.4, 6.4, 6.9, 7.1]
};
export const COUNTRIES_DATA = {
    labels: [
        "Colombia",
        "Perú",
        "Brasil",
        "Chile",
        "Ecuador",
        "Argentina",
        "Rep. Dom.",
        "México"
    ],
    values: [2850000, 1550000, 670000, 595000, 445000, 174000, 125000, 107000]
};
export const GLOBAL_ELDERLY_DATA = {
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
export const ESCALABILIDAD_DATA = {
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
export const MAYORES_DATA = {
    labels: [
        "Con hijos en exterior",
        "Hogares solo con mayores",
        "Sin medicamentos regulares"
    ],
    values: [65.6, 35.0, 45.3],
    colors: ["#818cf8", "#f87171", "#fb923c"]
};
export const RESPUESTA_DATA = {
    labels: ["Sin sistema\nde alerta", "Con llamada\nmanual", "Con En Casa"],
    values: [47, 22, 2],
    colors: ["#ef4444", "#f97316", "#22c55e"]
};
export const ESTADOS_DATA = {
    labels: ["Zulia", "Miranda", "Carabobo", "Bolívar", "Lara", "Mérida", "Anzoátegui", "Barinas", "Táchira", "Aragua"],
    vulnIdx: [88, 82, 79, 74, 71, 68, 65, 63, 61, 58],
    hijosExt: [72, 68, 65, 58, 54, 61, 49, 45, 57, 51]
};
export const KPI_MAIN = [
    { icon: "🌍", val: "≈7,9 M", label: "Venezolanos en el exterior", sub: "ACNUR/R4V · 2024", color: "#818cf8" },
    { icon: "👴", val: "3,6 M", label: "Adultos mayores (60+) en VE", sub: "12,7% de la población · WPP 2024 / Banco Mundial", color: "#a78bfa" },
    { icon: "🏠", val: "300–380 K", label: "Mayores solos por emigración", sub: "Convite AC · 2025", color: "#f87171" },
    { icon: "⏱️", val: "47 min", label: "Sin alerta de emergencia", sub: "Tiempo promedio sin En Casa", color: "#fbbf24" },
    { icon: "📱", val: "53 %", label: "Mayores con tecnología asistiva", sub: "Encuesta 2023 · adultos 55+", color: "#60a5fa" }
];
export const KPI_MAYORES = [
    { icon: "👴", val: "3,6 M", label: "Adultos mayores (60+)", sub: "12,7% de la población · WPP 2024 / Banco Mundial", color: "#818cf8" },
    { icon: "🏠", val: "300–380 K", label: "Viven solos · por emigración", sub: "Convite AC · 2025", color: "#f87171" },
    { icon: "💀", val: "28–35 %", label: "Caen cada año (65+)", sub: "OMS · Global Report on Falls 2007", color: "#f87171" },
    { icon: "⏳", val: "30 %", label: "Mayores de 90 que caen: >1h en suelo", sub: "Fleming & Brayne · BMJ 2008", color: "#a78bfa" }
];
export const FLOW_STEPS = [
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
        badge: "Verifica antes de escalar"
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
export const PROGRESS_ITEMS = [
    { label: "Hogares solo con mayores", val: 35.0, color: "#a78bfa" }
];
export const REFERENCES = [
    {
        icon: "🌐",
        title: "ACNUR/R4V — Plataforma Regional de Coordinación",
        year: "2024",
        desc: "≈7,9 M de venezolanos fuera del país. ≈395.000 refugiados y ≈1,3 M solicitantes de asilo. Más del 80% permanece en América Latina y el Caribe.",
        url: "https://www.r4v.info/es/refugiadosymigrantes"
    },
    {
        icon: "🌐",
        title: "HelpAge International & OIM — Migration and ageing: income security",
        year: "2023",
        desc: "Estudios sobre el síndrome del nido vacío migratorio: millones de adultos mayores quedan sin cuidadores en Latinoamérica, Europa del Este y Asia por el éxodo de generaciones productivas.",
        url: "https://www.helpage.org/what-we-do/migration/"
    },
    {
        icon: "📊",
        title: "Banco Mundial / World Population Prospects 2024",
        year: "2024",
        desc: "12,7% de la población venezolana tiene 60+ (≈3,6 M). 55 dependientes por cada 100 en edad activa. La proporción de mayores se duplica hacia 2050. 51 mayores por cada 100 menores.",
        url: "https://population.un.org/wpp/"
    },
    {
        icon: "📊",
        title: "CEPAL/CELADE — Envejecimiento en América Latina",
        year: "2023",
        desc: "Análisis demográficos sobre envejecimiento poblacional en la región.",
        url: "https://www.cepal.org/es/temas/envejecimiento"
    },
    {
        icon: "🏥",
        title: "OMS — Caídas: Datos y cifras",
        year: "2026",
        desc: "842.000 muertes/año por caídas. 2ª causa de muerte por lesión no intencional.",
        url: "https://www.who.int/news-room/fact-sheets/detail/falls"
    },
    {
        icon: "🏥",
        title: "OMS — Global Report on Falls Prevention in Older Age",
        year: "2007",
        desc: "28–35% de los mayores de 65 años cae cada año.",
        url: "https://www.who.int/publications/i/item/9789241563536"
    },
    {
        icon: "🏥",
        title: "Fleming & Brayne — Inability to get up after a fall (BMJ)",
        year: "2008",
        desc: "30% de los mayores de 90 años que caen pasa una hora o más en el suelo.",
        url: "https://pubmed.ncbi.nlm.nih.gov/19015185/"
    },
    {
        icon: "🏥",
        title: "Wild et al. — Study of old people found lying on the ground (BMJ)",
        year: "1981",
        desc: "La mitad de quienes yacen más de una hora en el suelo muere en los 6 meses siguientes (n=20).",
        url: "https://pubmed.ncbi.nlm.nih.gov/6779979/"
    },
    {
        icon: "🏥",
        title: "CDC — Falls Data & Research",
        year: "2024",
        desc: "Recursos y datos sobre prevención de caídas en adultos mayores.",
        url: "https://www.cdc.gov/falls/data-research/index.html"
    },
    {
        icon: "📋",
        title: "Convite AC — Adultos Mayores en Venezuela",
        year: "2025",
        desc: "300.000–380.000 mayores viven completamente solos como consecuencia de la emigración.",
        url: "https://www.conviteac.org"
    },
    {
        icon: "📋",
        title: "ENCOVI — Encuesta Nacional de Condiciones de Vida",
        year: "2023",
        desc: "Encuesta sobre condiciones de vida en Venezuela. 51 mayores por cada 100 menores — inversión demográfica.",
        url: "https://proyectoencovi.com"
    },
    {
        icon: "📱",
        title: "U.S. News & World Report — Aging in Place With Assistive Tech",
        year: "2023",
        desc: "53% de adultos 55+ usan tecnología asistiva (encuesta a 2.000 adultos).",
        url: "https://www.usnews.com/360-reviews"
    }
];
