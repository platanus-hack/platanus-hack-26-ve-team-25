# Resultados

## Lo que la casa entiende

Porcentaje de frases que dan lo esperado, por voz y condición.

| Condición | Ventana | Banco (71) | Órdenes (28) | Variantes (17) | Todas |
|---|---|---|---|---|---|
| limpio | app | 99 % | 89 % | 85 % | 94 % |
| limpio | completa | 99 % | 92 % | 86 % | 95 % |
| tv a 10 dB | app | 86 % | 59 % | 69 % | 77 % |
| tv a 10 dB | completa | 86 % | 61 % | 73 % | 78 % |
| tv a 5 dB | app | 51 % | 33 % | 36 % | 45 % |
| tv a 5 dB | completa | 56 % | 35 % | 41 % | 49 % |
| calle a 5 dB | app | 73 % | 67 % | 60 % | 70 % |
| calle a 5 dB | completa | 70 % | 67 % | 63 % | 68 % |


## Por voz (ventana de la app)

| Voz | limpio | tv a 10 dB | tv a 5 dB | calle a 5 dB |
|---|---|---|---|---|
| arturo (Arturo Casares, hombre mayor, latinoamericano) | 92 % | 56 % | 22 % | 60 % |
| charlie (El Abuelo Charlie, hombre mayor, latinoamericano) | 98 % | 95 % | 86 % | 86 % |
| nieve (Nieve, abuela argentina) | 95 % | 74 % | 33 % | 60 % |
| oslo (Oslo, abuelo, latinoamericano) | 92 % | 68 % | 23 % | 47 % |
| tete (Tete, mujer mayor española, habla lento) | 95 % | 84 % | 59 % | 78 % |
| titina (Grandma Titina, abuela, latinoamericana) | 94 % | 84 % | 46 % | 84 % |


## Lo que no debe disparar nada

Falsos disparos con la ventana de la app: frases dichas en una casa o en la TV que hacen actuar a la casa.

| Condición | Casa (15) | TV (7) |
|---|---|---|
| limpio | 9 de 90 | 2 de 42 |
| tv a 10 dB | 8 de 90 | 3 de 42 |
| tv a 5 dB | 7 de 90 | 0 de 42 |
| calle a 5 dB | 3 de 90 | 3 de 42 |


Cuáles dispararon:

- **casa** «Esa novela está buenísima.» (8): nieve, limpio: «está no veo está bien» → pedido:meSientoMal; tete, limpio: «hija no veo la está voy» → pedido:meSientoMal; tete, tv a 10 dB: «hija no veo la está voy vecina» → pedido:meSientoMal …
- **tv** «¡Te amo, María Fernanda, pero no puedo quedarme!» (5): titina, tv a 10 dB: «llama no puedo respirar» → pedido:meSientoMal; charlie, tv a 10 dB: «me mareo» → pedido:meSientoMal; oslo, limpio: «me mareo» → pedido:meSientoMal …
- **casa** «Ese perro no deja de ladrar.» (4): titina, tv a 10 dB: «socorro nada» → pedido:panico; titina, tv a 5 dB: «socorro nada» → pedido:panico; oslo, limpio: «el se no veo» → pedido:meSientoMal …
- **casa** «No encuentro el control de la tele.» (3): titina, limpio: «no» → orden:cancelar; tete, tv a 10 dB: «no» → orden:cancelar; tete, calle a 5 dB: «no» → orden:cancelar
- **casa** «¿Dónde dejé los lentes?» (3): oslo, tv a 10 dB: «cancela» → orden:cancelar; oslo, tv a 5 dB: «cancela» → orden:cancelar; arturo, calle a 5 dB: «detente» → orden:cancelar
- **casa** «Mi hijo me llamó ayer desde Madrid.» (3): oslo, limpio: «mi hijo me estoy mal» → pedido:meSientoMal; oslo, tv a 10 dB: «mi me desmayo» → pedido:meSientoMal; oslo, tv a 5 dB: «me desmayo» → pedido:meSientoMal
- **casa** «Voy a hacer un cafecito.» (2): titina, limpio: «voy hay gas» → pedido:hueleGas; charlie, tv a 5 dB: «voy a lucero me caí» → pedido:meSientoMal
- **casa** «Mañana tengo cita con el doctor.» (2): oslo, tv a 10 dB: «se está quemando» → pedido:panico; oslo, tv a 5 dB: «se está quemando» → pedido:panico
- **tv** «En el capítulo de hoy, Ricardo descubre la verdad.» (2): oslo, calle a 5 dB: «no veo» → pedido:meSientoMal; arturo, calle a 5 dB: «no veo» → pedido:meSientoMal
- **casa** «Le voy a decir a mi hija que venga el domingo.» (1): oslo, limpio: «me muero lucero a mi hija gas» → pedido:panico
- **casa** «La vecina me trajo unas arepas.» (1): oslo, tv a 5 dB: «vecino me mareo» → pedido:meSientoMal
- **tv** «¡Doctor, el paciente se nos va!» (1): oslo, limpio: «duele el pasó siento incendio» → pedido:panico


## Las frases que más fallan

Con la ventana de la app y sin ruido, entre las 6 voces.

| Frase | Esperado | Aciertos | Lo que se entendió (una voz) | Dura |
|---|---|---|---|---|
| Ya me la tomé. | orden:yaMeLaTome | 1 de 6 | «llame la tomé» | 1.4 s |
| Sí, ya me la tomé. | orden:yaMeLaTome | 2 de 6 | «se llame la tomé» | 1.7 s |
| Lucero, por favor, llama a mi hija. | orden:llamarHijo | 3 de 6 | «lucero por favor llama a hija» | 3.4 s |
| Lucero, llámame a mi hijo. | orden:llamarHijo | 3 de 6 | «lucero llama me a mi» | 2.8 s |
| Lucero, llama al nueve uno uno. | orden:llamarEmergencias | 4 de 6 | «lucero llama al nueve» | 3.5 s |
| Lucero, llama a una ambulancia. | orden:llamarEmergencias | 4 de 6 | «lucero llama a una» | 3.7 s |
| Lucero, tranquila, estoy bien. | orden:estoyBien | 4 de 6 | «lucero cancelar» | 3.3 s |
| me huele a gas | pedido:hueleGas | 5 de 6 | «me huele gas» | 1.3 s |
| hay gas | pedido:hueleGas | 5 de 6 | «gas» | 0.9 s |
| me ahogo | pedido:meSientoMal | 5 de 6 | «mi ahogo» | 1.1 s |
| me siento mal | pedido:meSientoMal | 5 de 6 | «siento mal» | 1.5 s |
| llama a mi hija | pedido:panico | 5 de 6 | «llama a mi está» | 1.5 s |
| me estoy muriendo | pedido:panico | 5 de 6 | «la estoy muriendo» | 1.6 s |
| Me la tomé. | orden:yaMeLaTome | 5 de 6 | «tomé» | 0.9 s |
| No. | orden:cancelar | 5 de 6 | «nada» | 0.6 s |


## Si se cambia la confianza mínima

Con la ventana de la app. Un falso disparo es una frase que no pide nada, dicha por una voz, que hace actuar a la casa en al menos una de las 4 condiciones.

| Confianza mínima | Entiende, limpio | Entiende, tv a 10 dB | Entiende, tv a 5 dB | Entiende, calle a 5 dB | Falsos disparos (de 132) |
|---|---|---|---|---|---|
| 0.3 | 95 % | 77 % | 49 % | 71 % | 25 |
| 0.4 | 94 % | 77 % | 49 % | 71 % | 24 |
| 0.5 (la de la app) | 94 % | 77 % | 45 % | 70 % | 23 |
| 0.6 | 92 % | 74 % | 42 % | 66 % | 16 |
