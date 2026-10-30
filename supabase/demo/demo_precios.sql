-- Opcional: llena precio, experiencia y servicios de los perfiles DEMO
-- (teléfonos 5930000…) para ver cómo lucen las tarjetas. No toca perfiles reales.
update public.profesionales p
set precio_desde = (array[10, 12, 15, 20, 25, 30])[1 + (abs(hashtext(p.id::text)) % 6)],
    anios_experiencia = 2 + (abs(hashtext(p.nombre_publico)) % 18),
    servicios = array['Instalaciones', 'Reparaciones', 'Mantenimiento', 'Emergencias 24h']
                [1 : 2 + (abs(hashtext(p.id::text)) % 3)]
from public.usuarios u
where u.id = p.usuario_id and u.telefono like '5930000%';
