import '../dominio/tipos.dart';

// Datos inventados para ver las pantallas sin backend. Nada real de nadie.
// Cuando Supabase esté listo, esto se reemplaza y las pantallas no cambian.

const casaSimulada = Casa(
  id: 'demo',
  nombre: 'Carmen',
  condiciones: ['oxigeno', 'hipertension'],
  contactos: [
    Contacto(
      nombre: 'María',
      relacion: 'hija',
      canal: Canal.telegram,
      orden: 1,
      donde: 'En Madrid',
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
