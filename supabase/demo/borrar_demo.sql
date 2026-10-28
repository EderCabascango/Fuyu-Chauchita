-- Borra todos los datos demo (usuarios con teléfono 5930000...).
-- En cascada se van sus perfiles, fotos, zonas, reseñas y contactos.
delete from auth.users where phone like '5930000%';
