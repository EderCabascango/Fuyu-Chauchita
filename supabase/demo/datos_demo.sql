-- =====================================================================
-- DATOS DEMO para probar la app. NO usar en producción.
-- Crea 13 profesionales ficticios (12 aprobados + 1 pendiente que NO
-- debe verse), con fotos, zonas y reseñas de 6 clientes ficticios.
--
-- Todos los teléfonos empiezan con 5930000 (números que no existen),
-- así ningún mensaje de prueba llega a una persona real.
-- Se puede ejecutar varias veces: primero borra la demo anterior.
-- Para quitarlo todo: supabase/demo/borrar_demo.sql
-- =====================================================================

do $$
declare
  demo jsonb := $json$[
    {"n":"Luis Cuzco","of":["Electricista"],"pa":["Cayambe","Ayora"],"disp":true,"ver":true,
     "desc":"Instalaciones eléctricas residenciales, cambio de tableros, tomacorrientes y lámparas. 12 años de experiencia.",
     "hor":"Lun a sáb, 7:00 a 18:00","fotos":3,"res":[[5,"Muy puntual y ordenado."],[5,"Arregló el tablero el mismo día."],[4,null]]},
    {"n":"Marco Farinango","of":["Electricista"],"pa":["Cangahua"],"disp":false,"ver":false,
     "desc":"Electricista para casas y negocios en Cangahua y comunidades.","hor":"Lun a vie, 8:00 a 17:00","fotos":1,"res":[[4,"Buen trabajo, precio justo."]]},
    {"n":"Rosa Imbaquingo","of":["Plomero"],"pa":["Cayambe","Juan Montalvo"],"disp":true,"ver":true,
     "desc":"Fugas, grifería, calefones y destape de tuberías. Atiendo emergencias.","hor":"Todos los días, 6:00 a 21:00","fotos":3,
     "res":[[5,"Llegó en 20 minutos por una fuga."],[4,null],[5,"Excelente, muy recomendada."],[5,null]]},
    {"n":"Jorge Quilumbaquí","of":["Plomero","Albañil"],"pa":["Olmedo","Ayora"],"disp":false,"ver":true,
     "desc":"Plomería y albañilería: baños completos, cerámica y reparaciones.","hor":"Lun a sáb","fotos":2,"res":[[4,null],[3,"Buen trabajo pero tardó más de lo dicho."]]},
    {"n":"Segundo Tituaña","of":["Carpintero"],"pa":["Cayambe"],"disp":false,"ver":true,
     "desc":"Muebles a medida, puertas, closets y cocinas en madera.","hor":"Lun a vie, 8:00 a 17:00","fotos":3,"res":[[5,"El closet quedó perfecto."],[5,null]]},
    {"n":"Diego Pillajo","of":["Albañil","Pintor"],"pa":["Cayambe","Ascázubi"],"disp":true,"ver":false,
     "desc":"Construcción, enlucidos, pintura interior y exterior.","hor":"Lun a sáb","fotos":0,"res":[]},
    {"n":"Taller Hermanos Andrango","of":["Mecánico"],"pa":["Cayambe","Juan Montalvo"],"disp":false,"ver":true,
     "desc":"Mecánica general, frenos, suspensión y diagnóstico por computadora.","hor":"Lun a sáb, 8:00 a 18:00","fotos":2,"res":[[4,null],[5,"Honestos con el diagnóstico."],[4,null]]},
    {"n":"Gas Express Cayambe","of":["Gas a domicilio"],"pa":["Cayambe","Ayora","Juan Montalvo"],"disp":true,"ver":true,
     "desc":"Entrega de cilindros de gas a domicilio en 30 minutos.","hor":"Todos los días, 6:00 a 20:00","fotos":1,"res":[[5,"Rapidísimo."],[5,null],[5,"Siempre cumplen."]]},
    {"n":"Fernando Ulcuango","of":["Pintor"],"pa":["Otón","Cusubamba"],"disp":false,"ver":false,
     "desc":"Pintura de casas, fachadas y empastado.","hor":"Lun a sáb","fotos":2,"res":[[3,null]]},
    {"n":"Cerrajería La Llave","of":["Cerrajero"],"pa":["Cayambe"],"disp":true,"ver":true,
     "desc":"Apertura de puertas, copias de llaves, cambio de chapas. Servicio 24 horas.","hor":"24 horas","fotos":1,"res":[[5,"Me abrieron la puerta a medianoche."]]},
    {"n":"Patricio Catucuamba","of":["Soldador"],"pa":["Cangahua","Cayambe"],"disp":false,"ver":false,
     "desc":"Puertas, ventanas y estructuras metálicas. Soldadura en general.","hor":"Lun a vie","fotos":2,"res":[]},
    {"n":"Wilson Nepas","of":["Técnico de electrodomésticos"],"pa":["Cayambe","Ayora"],"disp":true,"ver":true,
     "desc":"Reparación de refrigeradoras, lavadoras, cocinas y microondas.","hor":"Lun a sáb, 8:00 a 18:00","fotos":2,"res":[[4,null],[5,"Dejó la lavadora como nueva."]]},
    {"n":"Perfil pendiente (NO debe verse)","of":["Electricista"],"pa":["Cayambe"],"disp":true,"ver":false,
     "desc":"Este perfil está pendiente de aprobación.","hor":null,"fotos":0,"res":[],"pendiente":true}
  ]$json$;
  p        jsonb;
  r        jsonb;
  i        int := 0;
  k        int;
  v_user   uuid;
  v_prof   uuid;
  clientes uuid[] := '{}';
begin
  -- Limpiar la demo anterior (borrar el usuario borra todo en cascada)
  delete from auth.users where phone like '5930000%';

  -- 6 clientes ficticios para las reseñas
  for k in 1..6 loop
    v_user := gen_random_uuid();
    insert into auth.users (id, instance_id, aud, role, phone, created_at, updated_at)
    values (v_user, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            '5930000002' || lpad(k::text, 2, '0'), now(), now());
    clientes := clientes || v_user;
  end loop;

  for p in select * from jsonb_array_elements(demo) loop
    i := i + 1;
    v_user := gen_random_uuid();
    insert into auth.users (id, instance_id, aud, role, phone, created_at, updated_at)
    values (v_user, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            '5930000001' || lpad(i::text, 2, '0'), now(), now());

    insert into public.profesionales
      (usuario_id, nombre_publico, descripcion, whatsapp, horario, disponible_ahora, estado, verificado)
    values
      (v_user, p->>'n', p->>'desc', '5930000001' || lpad(i::text, 2, '0'), p->>'hor',
       (p->>'disp')::boolean,
       case when (p->>'pendiente')::boolean then 'pendiente' else 'aprobado' end,
       (p->>'ver')::boolean)
    returning id into v_prof;

    insert into public.profesional_oficio (profesional_id, oficio_id)
    select v_prof, o.id from public.oficios o
    where o.nombre in (select jsonb_array_elements_text(p->'of'));

    insert into public.profesional_parroquia (profesional_id, parroquia_id)
    select v_prof, pa.id from public.parroquias pa
    where pa.nombre in (select jsonb_array_elements_text(p->'pa'));

    for k in 1..(p->>'fotos')::int loop
      insert into public.fotos_trabajo (profesional_id, url, orden)
      values (v_prof, 'https://picsum.photos/seed/oficios-' || i || '-' || k || '/600/600', k);
    end loop;

    k := 0;
    for r in select * from jsonb_array_elements(p->'res') loop
      k := k + 1;
      insert into public.resenas (profesional_id, cliente_id, estrellas, comentario, creado_en)
      values (v_prof, clientes[k], (r->>0)::smallint, r->>1, now() - (k * 9 || ' days')::interval);
    end loop;
  end loop;
end
$$;

-- Resumen de lo creado
select nombre_publico, estado, disponible_ahora, verificado, promedio_estrellas, total_resenas
from public.profesionales
where whatsapp like '5930000%'
order by estado, disponible_ahora desc, promedio_estrellas desc;
