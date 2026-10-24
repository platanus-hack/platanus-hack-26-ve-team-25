import '../dominio/pastillas.dart';
import '../dominio/tipos.dart';

// Datos inventados para ver las pantallas sin backend. Cuando Supabase esté listo, esto se
// reemplaza y las pantallas no cambian.
//
// El número de emergencia NO va en el código: el repo es público. Se pasa al correr la app,
// desde config/local.json, que no se sube (ver config/local.example.json y el README).
const telefonoEmergencia = String.fromEnvironment('TELEFONO_EMERGENCIA');
const telefonoVecino = String.fromEnvironment('TELEFONO_VECINO');

/// El número al que llama «Lucero, llama a emergencias». En Venezuela es el 911, pero no viene
/// puesto: para probar se usa el de alguien del equipo, nunca el 911 de verdad.
const numeroEmergencias = String.fromEnvironment('NUMERO_EMERGENCIAS');

const casaSimulada = Casa(
  id: 'demo',
  nombre: 'Carmen',
  condiciones: ['oxigeno', 'hipertension'],
  contactos: [
    Contacto(
      nombre: 'Josuep',
      relacion: 'hijo',
      canal: Canal.llamada,
      orden: 1,
      donde: 'En Caracas',
      telefono: telefonoEmergencia,
    ),
    Contacto(
      nombre: 'Pedro',
      relacion: 'vecino',
      canal: Canal.llamada,
      orden: 2,
      donde: 'En Caracas',
      telefono: telefonoVecino,
    ),
  ],
);

const pastillasSimuladas = [
  Pastilla(
    id: 'losartan-manana',
    nombre: 'Losartán',
    dosis: '50 mg',
    hora: 8,
    minuto: 0,
    colores: [0xFFF4F4F0, 0xFF60A5FA],
  ),
  Pastilla(
    id: 'metformina',
    nombre: 'Metformina',
    dosis: '500 mg',
    hora: 14,
    minuto: 0,
    colores: [0xFFF4F4F0],
    indicacion: '1 pastilla, con la comida',
  ),
  Pastilla(
    id: 'losartan-noche',
    nombre: 'Losartán',
    dosis: '50 mg',
    hora: 20,
    minuto: 0,
    colores: [0xFFF4F4F0, 0xFF60A5FA],
  ),
];
