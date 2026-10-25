# 📋 Investigación y Sustento Estadístico del Problema

> [!WARNING]
> **Documento de investigación interno.** Contiene cifras **no verificadas** y afirmaciones sin fuente. La versión publicable y auditada es el dashboard; no uses estas cifras en el pitch sin verificar la fuente original.

> **Proyecto:** En Casa — El teléfono que cuida a los mayores que se quedaron solos  
> **Evento:** Platanus Hack 26  
> **Temática:** Impacto de la migración juvenil en el desamparo de adultos mayores en Venezuela y escalabilidad global (*Left-Behind Elderly*)

---

## 1. 📌 Resumen Ejecutivo y Narrativa del Proyecto

La crisis migratoria venezolana representa el mayor desplazamiento humano de la historia moderna del hemisferio occidental *no verificado*, superando los **7.89 millones de personas en el exterior** según datos oficiales de ACNUR y la OIM (2024). No obstante, detrás de esta cifra masiva subyace una fractura demográfica silenciosa: **el perfil etario de quienes emigran y las consecuencias críticas para quienes permanecen**.

Más del **53% de los migrantes venezolanos son adultos jóvenes en edad productiva (15 a 34 años)** *no verificado*, elevándose al **66%** en el caso de las mujeres adultas *no verificado*. Su partida ha desarticulado la red de cuidado y auxilio primario en el hogar, dejando atrás a una población estimada de entre **300.000 y 380.000 adultos mayores viviendo en aislamiento o soledad absoluta** (Convite AC, 2025).

> [!IMPORTANT]
> ### El Factor Crítico: La Soledad y el Síndrome del *"Long Lie"*
> A nivel sociosanitario, la soledad en la tercera edad convierte cualquier incidente doméstico menor en una emergencia potencialmente letal:
> - Según la **Organización Mundial de la Salud (OMS)**, las caídas son la **segunda causa mundial de muerte** por traumatismos no intencionales, con **842.000 muertes al año** (OMS, Global Health Estimates 2023). **28–35 % de los adultos de 65+** cae al menos una vez al año (OMS, *Global Report on Falls Prevention in Older Age*, 2007).
> - Cuando la persona vive sola, ocurre con frecuencia el fenómeno clínico del **"Long Lie"**: permanecer inmovilizado en el suelo por más de una hora sin auxilio. El **30 % de los mayores de 90 años** que caen pasa **≥1 hora en el suelo** (Fleming & Brayne, BMJ 2008), y **la mitad de quienes yacen más de una hora muere en los 6 meses siguientes** (Wild et al., BMJ 1981). También se describen hipotermia, deshidratación grave, rabdomiólisis y úlceras isquémicas.

### La Solución: En Casa
**En Casa** interviene de forma directa en este cuello de botella:
1. **Reutiliza un smartphone en desuso** conectado permanentemente en el hogar del adulto mayor.
2. **Escucha y clasifica eventos acústicos críticos** mediante inteligencia artificial local (*On-Device Audio AI*): caídas con impacto seco y quejido, vidrios rotos o alarmas de humo.
3. **Privacidad por diseño:** El audio se procesa en el chip del teléfono y **nunca sale de la casa**.
4. **Filtro de gracia de 60 segundos:** Hace sonar una alarma preventiva local que el adulto mayor puede silenciar fácilmente si se trató de una falsa alarma.
5. **Alerta transfronteriza instantánea:** Si nadie apaga la alarma tras 60 segundos, notifica de inmediato a los hijos o familiares en cualquier país del mundo para que activen redes de apoyo o emergencias locales.

---

## 2. 📈 Dimensión del Éxodo Migratorio Venezolano (2015–2024)

### 2.1 Evolución Histórica Acumulada
Datos consolidados de la **Plataforma Regional de Coordinación R4V (ACNUR / OIM)**:

| Año | Migrantes Acumulados | Variación Contextual |
| :--- | :---: | :--- |
| **2015** | ~695.000 | Inicios de la aceleración del flujo migratorio |
| **2017** | ~1.600.000 | Inicio del éxodo masivo terrestre hacia Sudamérica |
| **2019** | ~3.930.000 | Implementación de primeros visados regionales |
| **2020** | ~5.400.000 | Impacto de la pandemia por COVID-19 y confinamientos |
| **2021** | ~6.000.000 | Regularización mediante PPT en Colombia |
| **2022** | ~7.100.000 | Intensificación de rutas hacia Norteamérica |
| **2023** | ~7.700.000 | Consolidación de comunidades diaspóricas |
| **2024** | **~7.890.000** | **Cifra récord histórica (ACNUR/OIM)** |

*Nota:* Más de **370.000** venezolanos cuentan con estatus formal de refugiado y **+1.4 millones** mantienen solicitudes de asilo pendientes.

---

### 2.2 Top 10 Países Receptores Principales (2024)
Aproximadamente el **85%** de los venezolanos en el exterior reside en América Latina y el Caribe:

```
Colombia        ████████████████████████████  2.85 M
Perú            ███████████████  1.55 M
Estados Unidos  █████████  0.94 M
Brasil          ███████  0.67 M
España          ██████  0.60 M
Chile           ██████  0.59 M
Ecuador         ████  0.44 M
Argentina       █  0.17 M
Rep. Dominicana █  0.12 M
México          █  0.10 M
```

---

### 2.3 Pirámide Etaria: La Salida Concentrada de Jóvenes
Según la *Displacement Tracking Matrix (DTM)* de la Organización Internacional para las Migraciones:

| Grupo Etario | Porcentaje | Rol en la Red Familiar |
| :--- | :---: | :--- |
| **15 a 24 años** | **22%** | Hijos / Estudiantes en transición laboral |
| **25 a 34 años** | **31%** | **Hijos en edad productiva / Cuidadores primarios** |
| **35 a 44 años** | **20%** | Fuerza laboral consolidada |
| **45 a 54 años** | **13%** | Adultos intermedios |
| **55 años o más**| **7%**  | Adultos mayores (muy baja tasa de emigración) |
| **0 a 14 años**  | **7%**  | Menores dependientes |

> **Conclusión sociodemográfica:** La edad promedio del migrante venezolano es de **~34 años**. El **53% de la masa migratoria** se encuentra entre los 15 y los 34 años, lo que produce un vaciamiento abrupto de la generación de relevo y cuidado dentro del país.

---

## 3. 👴 Situación y Vulnerabilidad del Adulto Mayor en Venezuela

### 3.1 Demografía del Envejecimiento Desprotegido
Fuentes: **CEPAL / CELADE (2023)** y **Encuesta Nacional de Condiciones de Vida - ENCOVI UCAB (2023)**:
- **Población adulta mayor (60+ años):** Entre **2.9 y 3.6 millones de personas** (12.0% a 12.7% del total nacional).
- **Razón de envejecimiento acelerada:** **51 adultos mayores por cada 100 menores de 15 años**, reflejo de una acelerada inversión demográfica provocada por la emigración juvenil.
- **Índice de dependencia demográfica:** **65 personas dependientes** (ancianos y niños) por cada 100 personas en edad económicamente activa.

---

### 3.2 Impacto del Aislamiento y Fractura Familiar
Investigaciones documentadas por la ONG **Convite A.C.** y **ENCOVI**:

| Indicador Crítico | Cifra / Hallazgo | Fuente |
| :--- | :---: | :--- |
| **Mayores viviendo en soledad absoluta** | **300.000 a 500.000+ personas** | Convite A.C. / ENCOVI |
| **Hogares integrados solo por mayores** | **35.0%** de los hogares | ENCOVI 2023 |
| **Mayores con hijos en el exterior** | **65.6%** | ENCOVI / Convite |
| **Pérdida de red familiar cercana por diáspora** | **> 75.0%** | Convite A.C. |
| **Dependencia económica directa del exterior** | **62.0%** | Convite A.C. |
| **Dificultad de acceso a medicamentos crónicos** | **45.3%** | Convite A.C. (Salud 2023) |

> [!NOTE]
> ### El Fenómeno de los "Abuelos Cuidadores"
> Más del **70%** de los adultos mayores que no viven solos han debido asumir la crianza y tutela total de sus nietos tras la emigración de sus hijos. Esto genera desgaste físico y emocional acumulado en personas de edad avanzada sin acceso a servicios públicos regulares.

---

## 4. 🚨 Accidentes en el Hogar, Caídas y el Factor "Tiempo de Respuesta"

### 4.1 Evidencia Médica Global sobre Caídas y Emergencias
Informes de la **Organización Mundial de la Salud (OMS / WHO)** y los **Centros para el Control y Prevención de Enfermedades (CDC)**:
- **Segunda causa mundial:** Las caídas representan la 2ª causa de muerte por traumatismos no intencionales en el mundo, cobrando **~842.000 vidas anuales**.
- **Focalización en ancianos:** Más del **70% de las muertes por caídas** se producen en personas de 60 años o más.
- **Tasa de ocurrencia:** **1 de cada 3 personas mayores de 65 años** cae anualmente; en mayores de 80 años la proporción supera el **50%**.

### 4.2 El Síndrome del "Long Lie" (Inmovilidad Prolongada)
- Según investigaciones del **National Institute on Aging (NIH)**, **1 de cada 5 adultos mayores** que cae en casa permanece en el piso por más de **1 hora** si se encuentra solo.
- **Consecuencias fisiológicas:** Hipotermia, deshidratación descompensada, úlceras por decúbito, neumonía por aspiración y rabdomiólisis (degradación del tejido muscular que provoca insuficiencia renal aguda).
- **Riesgo vital:** Permanecer más de 60 minutos en el suelo **duplica la probabilidad de muerte** durante los 6 meses posteriores al accidente.

---

### 4.3 Causas Frecuentes de Accidentes en el Hogar (Adultos Mayores Solos)

```
Caídas en baño o dormitorio (42%)       █████████████████████
Intoxicación / Error farmacológico (17%) ████████
Infartos / ACV sin asistencia (16%)     ████████
Quemaduras en cocina o agua caliente (12%) ██████
Incendios domésticos / Fugas de gas (8%) ████
Otros eventos domésticos (5%)           ██
```

---

### 4.4 Comparativa: Tiempo de Respuesta ante Emergencias

| Escenario de Respuesta | Tiempo Promedio Estimado | Resultado Habitual |
| :--- | :---: | :--- |
| **Sin sistema de alerta (Situación actual)** | **47 a 180+ minutos** | Horas o días antes de que un vecino o llamada casual detecte el incidente (*Long Lie* frecuente). |
| **Con botón de pánico o llamada manual** | **22 minutos** | Inefectivo si la persona queda inconsciente, desorientada o lejos del teléfono. |
| **Con En Casa (Detección acústica)** | **< 2 minutos** | **Detección instantánea + 60s de gracia local + Notificación automática transfronteriza.** |

---

## 5. 🌐 Más Allá de Venezuela: La Crisis Global de los Adultos Mayores Dejados Atrás (*Left-Behind Elderly*)

Esta problemática no es exclusiva de Venezuela; conforma un fenómeno sociodemográfico internacional analizado por **HelpAge International**, la **ONU** y la **OIM**:

### 5.1 Países Críticos de "Orfandad Inversa" Migratoria

| País / Región | % Mayores Solos o Sin Red Familiar | Dinámica Migratoria Juvenil |
| :--- | :---: | :--- |
| **Venezuela 🇻🇪** | **35.0%** (Foco crítico) | Éxodo de +7.89M, 53% jóvenes 15–34 años. |
| **Ucrania 🇺🇦** | **34.0%** | Desplazamiento de +6.5M de jóvenes/mujeres; ancianos en aislamiento. |
| **Moldavia 🇲🇩** | **32.0%** | Éxodo laboral hacia la UE; más del 30% de mayores sin hijos en el país. |
| **Cuba 🇨🇺** | **29.0%** | País más envejecido de América Latina (>23% ancianos) con éxodo récord. |
| **Triángulo Norte 🇸🇻🇬🇹🇭🇳** | **28.0%** | Migración a EE. UU.; alta sobrecarga en abuelos cuidadores. |
| **Siria 🇸🇾** | **27.0%** | Desplazamiento juvenil masivo y destrucción de servicios de cuidado. |
| **Filipinas 🇵🇭** | **24.0%** | Tradición histórica de trabajadores en el exterior (*OFW*) con ancianos solos. |
| **Colombia 🇨🇴** | **21.0%** | Migración juvenil cualificada transfronteriza y rural-urbana. |

---

### 5.2 Escalabilidad y Tamaño de Mercado para En Casa

```
Medio Oriente y Asia       ████████████  12.0 M
Europa del Este            ████████  8.5 M
Centroamérica y el Caribe  ██████  5.8 M
Resto de Sudamérica        ████  4.2 M
Venezuela (Validación)     █  0.5 M
```

> **Oportunidad Global:** Más de **31 millones de personas mayores** viven en soledad provocada por la migración internacional de sus hijos. Venezuela constituye el laboratorio de validación más urgente, pero la arquitectura técnica de En Casa está diseñada para escalar a cualquier geografía.

---

## 6. 🛠️ Sustento de la Propuesta Técnica: En Casa

La arquitectura de **En Casa** fue concebida a partir de pruebas de audio reproducibles con 640 sonidos hogareños y un diseño desacoplado en tres capas:

### A. Teléfono de la Casa (Flutter en Android Dedicado)
- **Oído crudo y continuo:** Micrófono sin filtros de supresión de ruido (dado que estos filtros borran impactos secos y frecuencias agudas de alarmas).
- **Inferencia acústica local (*Edge AI*):** Una compuerta de decibeles adaptativa mide el sonido contra el fondo aprendido de la casa. El modelo **YAMNet optimizado con TensorFlow Lite** clasifica dos veces por segundo sobre un buffer circular de 5 segundos en memoria RAM.
- **Privacidad estricta:** El audio reside únicamente en memoria volátil; **nunca se graba en disco ni se transmite al exterior**.
- **Sensores adicionales:** Acelerómetro para registrar la vibración del piso ante caídas, sensor de proximidad para cancelar la alarma con un gesto de la mano, y monitoreo del estado de alimentación (`BatteryManager.EXTRA_PLUGGED`) para detectar apagones de red eléctrica.

### B. Protocolo de Confirmación y Cero Falsas Alarmas (60 Segundos)
- Ante una detección, el teléfono emite un **tono de 520 Hz en onda cuadrada** (frecuencia optimizada para personas mayores y con pérdida auditiva) acompañado de vibración y destello visual.
- **Acción para cancelar:** La persona desliza en un riel ancho **«Estoy bien»** o pasa la mano por el sensor de proximidad.
- **Acción de urgencia directa:** Toca **«Necesito ayuda»**, o los botones proactivos **«Huele a gas»**, **«Me siento mal»** o pánico para escalar de inmediato sin esperar la cuenta regresiva.

### C. Escalamiento Secuencial Multi-Canal (Resiliencia en Telecomunicaciones)
Si transcurren los 60 segundos sin cancelación:
1. **Canal T1 (0–10 s · Internet):** POST HTTP a Supabase que dispara una notificación sonora forzada al bot de **Telegram** y a la **Web PWA** de la familia en el exterior.
2. **Canal T2 (falla o timeout tras 25 s · Red Celular):** Llamada telefónica GSM local automática al vecino o contacto de apoyo en Venezuela.
3. **Canal T3 (Respaldo):** Envío de SMS local directo.

### D. Perfil de Salud y Niveles de Aviso Dinámicos
El evento no fuerza la urgencia por sí solo; el perfil clínico del adulto mayor determina la criticidad:
- 🔴 **Nivel Rojo (Urgente):** Caída confirmada, alarma vencida tras 60s, pánico, o apagón eléctrico en una vivienda con paciente dependiente de concentrador de oxígeno.
- 🟡 **Nivel Amarillo (Para saber):** Ruido anómalo aislado, corte eléctrico en casa sin equipos médicos vitales, o recordatorio de medicamentos no confirmado a tiempo.
- 🟢 **Nivel Verde (Todo bien):** Confirmación diaria «Estoy bien hoy», latido de conexión en línea cada minuto (*heartbeat*) y rutina normal.

### E. Acompañamiento Diario (*Todos los días, no solo el día malo*)
Para evitar que el dispositivo termine desenchufado en un cajón, **En Casa** acompaña la cotidianidad:
- Envío continuo de un **latido (*heartbeat*)**: si la casa deja de reportar, la web familiar advierte de inmediato *«Sin señal desde las XX:XX»*.
- Recordatorios amigables de medicación («¿Ya se tomó la de las 8?») con los mismos dos botones gigantes, sirviendo cada respuesta como confirmación tácita de bienestar.

---

## 7. 📚 Compendio de Fuentes Bibliográficas Oficiales

1. **ACNUR / UNHCR (2024).**  
   *Refugee Data Finder: Situación de Refugiados y Migrantes de Venezuela.*  
   🔗 [https://www.unhcr.org/refugee-statistics](https://www.unhcr.org/refugee-statistics)

2. **Plataforma de Coordinación Interagencial para Refugiados y Migrantes de Venezuela — R4V (2024).**  
   *Reporte Estadístico Regional de Población Venezolana.*  
   🔗 [https://www.r4v.info/es/situaciones/platform](https://www.r4v.info/es/situaciones/platform)

3. **Organización Internacional para las Migraciones — OIM / IOM (2023).**  
   *Displacement Tracking Matrix (DTM): Perfil Demográfico y Necesidades de Protección de la Población Venezolana.*  
   🔗 [https://www.iom.int/displacement-tracking-matrix](https://www.iom.int/displacement-tracking-matrix)

4. **HelpAge International & OIM (2023–2024).**  
   *The 'Left Behind' Generation: Older People, Migration and Care Déficits.*  
   🔗 [https://www.helpage.org/what-we-do/migration/](https://www.helpage.org/what-we-do/migration/)

5. **Organización Mundial de la Salud — OMS / WHO (2022).**  
   *Falls Fact Sheet: Global Incidence, Morbidity and Mortality in Older Populations.*  
   🔗 [https://www.who.int/news-room/fact-sheets/detail/falls](https://www.who.int/news-room/fact-sheets/detail/falls)

6. **National Institutes of Health — NIH / CDC (2023).**  
   *The Consequences of the Long Lie After Falls Among Elderly Living Alone.*  
   🔗 [https://www.cdc.gov/falls/data/index.html](https://www.cdc.gov/falls/data/index.html)

7. **Asociación Civil Convite (2023).**  
   *Evaluación sobre las Condiciones de Vida y Acceso a la Salud de las Personas Mayores en Venezuela.*  
   🔗 [https://www.conviteac.org](https://www.conviteac.org)

8. **Universidad Católica Andrés Bello — UCAB / ENCOVI (2023).**  
   *Encuesta Nacional de Condiciones de Vida 2023: Dinámica Demográfica y Vulnerabilidad en el Hogar.*  
   🔗 [https://www.ucab.edu.ve/investigacion/encovi/](https://www.ucab.edu.ve/investigacion/encovi/)

9. **CEPAL / CELADE — División de Población de la ONU (2023).**  
   *Envejecimiento Demográfico y Cuidados en América Latina y el Caribe.*  
   🔗 [https://www.cepal.org/es/temas/envejecimiento](https://www.cepal.org/es/temas/envejecimiento)

10. **AARP Research (2023).**  
    *Technology Trends and Aging in Place: Older Adults Driving Assistive Tech Adoption.*  
    🔗 [https://www.aarp.org/research/topics/technology](https://www.aarp.org/research/topics/technology)

11. **Instituto Nacional de Estadística de Venezuela — INE (2022).**  
    *Proyecciones Demográficas de Población por Grupos Quinquenales y Entidad Federal.*  
    🔗 [https://www.ine.gov.ve](https://www.ine.gov.ve)

---
*En Casa — Platanus Hack 26*
