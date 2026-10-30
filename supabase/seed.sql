-- =====================================================================
-- Datos semilla: oficios y parroquias del cantón Cayambe.
-- Se puede ejecutar varias veces sin duplicar datos.
-- `icono` es el nombre de un ícono de Material (Icons.<icono> en Flutter).
-- =====================================================================

insert into public.oficios (nombre, icono, orden) values
  ('Electricista',                 'electrical_services', 1),
  ('Plomero',                      'plumbing',            2),
  ('Carpintero',                   'carpenter',           3),
  ('Albañil',                      'construction',        4),
  ('Mecánico',                     'car_repair',          5),
  ('Gas a domicilio',              'propane_tank',        6),
  ('Pintor',                       'format_paint',        7),
  ('Cerrajero',                    'key',                 8),
  ('Soldador',                     'hardware',            9),
  ('Técnico de electrodomésticos', 'kitchen',            10),
  ('Cámaras de seguridad',         'videocam',           11),
  ('Técnico en telecomunicaciones','cell_tower',         12),
  ('Técnico en computadoras',      'computer',           13),
  ('Taxis',                        'local_taxi',         14)
on conflict (nombre) do nothing;

insert into public.parroquias (nombre, canton) values
  ('Cayambe',       'Cayambe'),
  ('Ayora',         'Cayambe'),
  ('Juan Montalvo', 'Cayambe'),
  ('Cangahua',      'Cayambe'),
  ('Olmedo',        'Cayambe'),
  ('Otón',          'Cayambe'),
  ('Ascázubi',      'Cayambe'),
  ('Cusubamba',     'Cayambe')
on conflict (nombre, canton) do nothing;
