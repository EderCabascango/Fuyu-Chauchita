-- Oficios nuevos: Delivery y Arreglos florales.
-- Ejecutar DESPUÉS de 20261030000000_seguridad_y_oficios.sql. Se puede ejecutar más de una vez.

insert into public.oficios (nombre, icono, orden) values
  ('Delivery',          'delivery_dining', 15),
  ('Arreglos florales', 'local_florist',   16)
on conflict (nombre) do nothing;
