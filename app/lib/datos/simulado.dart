import '../dominio/tipos.dart';

// Datos inventados para ver las pantallas sin backend. Cuando Supabase esté listo, esto se
// reemplaza y las pantallas no cambian.
//
// El número de emergencia NO va en el código: el repo es público. Se pasa al correr la app,
// desde config/local.json, que no se sube (ver config/local.example.json y el README).
const telefonoEmergencia = String.fromEnvironment('TELEFONO_EMERGENCIA');

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
    ),
  ],
);
