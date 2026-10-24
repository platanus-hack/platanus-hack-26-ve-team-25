# App de la casa (Flutter, Android)

El teléfono viejo que queda enchufado en la casa del adulto mayor. Hoy tiene las cuatro pantallas
de los mockups con datos simulados y la máquina de estados de la alerta con pruebas. El oído, la
conexión a Supabase y los sensores todavía no están: ver [docs/pantallas.md](../docs/pantallas.md).

## Correrla en un Android

1. En el teléfono: Ajustes → Acerca del teléfono → tocar 7 veces «Número de compilación». Luego,
   en Opciones de desarrollador, activar «Depuración USB».
2. Conectarlo por USB, aceptar el aviso de depuración y comprobar que aparece:

```bash
flutter devices
```

3. Correr la app (con `r` en la terminal se recargan los cambios al instante):

```bash
flutter run
```

Para el demo, con la cuenta regresiva de 15 s en vez de 60 s:

```bash
flutter run --dart-define=DEMO=true
```

## Cómo probar las pantallas

Mientras no exista el oído, la app tiene dos toques largos de prueba:

| Gesto | Qué hace |
|---|---|
| Mantener presionado el reloj | Simula una alarma de humo: abre «¿Está bien?» con la cuenta regresiva |
| Mantener presionado «Cuidando la casa» | Abre la configuración, que en el producto usa el familiar |
| Tocar «Pedir ayuda», «Huele a gas» o «Me siento mal» | Avisa a la familia sin esperar: abre «Ya avisamos a su familia» |

Si la cuenta regresiva llega a cero, la alerta escala sola.

## Dónde está cada cosa

```text
lib/dominio/tipos.dart      el contrato compartido con la web de la familia
lib/dominio/alerta.dart     la máquina de estados de la alerta, en Dart puro
lib/datos/simulado.dart     la casa inventada de «Carmen»
lib/ui/raiz.dart            elige la pantalla según el estado: no hay menús
lib/ui/                     reposo, alarma («¿Está bien?»), ayuda y configuración
lib/tema.dart               colores y tipografía Atkinson Hyperlegible, que va dentro de la app
test/                       pruebas de la alerta y de las pantallas
```

```bash
flutter analyze
flutter test
```
