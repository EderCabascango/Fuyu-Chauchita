-- Oficio nuevo: Técnico de lavadoras y refrigeradoras.
-- Ejecutar DESPUÉS de 20261101000000_precio_experiencia_servicios.sql. Se puede ejecutar más de una vez.

insert into public.oficios (nombre, icono, orden) values
  ('Técnico de lavadoras y refrigeradoras', 'local_laundry_service', 17)
on conflict (nombre) do nothing;
