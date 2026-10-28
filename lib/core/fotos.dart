import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

const _bucket = 'fotos';

/// Tamaño objetivo de cada foto (la spec pide ~200 KB para ahorrar datos).
const _maxBytes = 220 * 1024;

/// Abre la galería o la cámara y devuelve la foto comprimida en JPG,
/// o `null` si el usuario canceló.
Future<Uint8List?> elegirFoto({required bool camara}) async {
  final archivo = await ImagePicker().pickImage(
    source: camara ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 2000,
    maxHeight: 2000,
  );
  if (archivo == null) return null;
  return comprimir(await archivo.readAsBytes());
}

/// Comprime a JPG bajando calidad y tamaño hasta quedar en ~200 KB.
Future<Uint8List> comprimir(Uint8List original) async {
  var lado = 1280;
  var calidad = 80;
  var resultado = original;
  for (var intento = 0; intento < 6; intento++) {
    resultado = await FlutterImageCompress.compressWithList(
      original,
      minWidth: lado,
      minHeight: lado,
      quality: calidad,
      format: CompressFormat.jpeg,
    );
    if (resultado.lengthInBytes <= _maxBytes) break;
    calidad = (calidad - 12).clamp(40, 100);
    lado = (lado * 0.85).round();
  }
  return resultado;
}

/// Sube la foto a la carpeta del usuario y devuelve su URL pública.
Future<String> subirFoto(Uint8List bytes, {required String prefijo}) async {
  final uid = supabase.auth.currentUser!.id;
  final ruta = '$uid/${prefijo}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await supabase.storage.from(_bucket).uploadBinary(
        ruta,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '31536000'),
      );
  return supabase.storage.from(_bucket).getPublicUrl(ruta);
}

/// Ruta dentro del bucket a partir de la URL pública (o `null` si es externa).
String? rutaDesdeUrl(String url) {
  const marca = '/storage/v1/object/public/$_bucket/';
  final i = url.indexOf(marca);
  if (i < 0) return null;
  return Uri.decodeComponent(url.substring(i + marca.length).split('?').first);
}

/// Borra una foto subida por la app. Ignora URLs externas y errores.
Future<void> borrarFoto(String? url) async {
  final ruta = url == null ? null : rutaDesdeUrl(url);
  if (ruta == null) return;
  try {
    await supabase.storage.from(_bucket).remove([ruta]);
  } catch (_) {}
}

/// Borra todas las fotos del usuario actual (al eliminar la cuenta).
Future<void> borrarTodasMisFotos() async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return;
  try {
    final archivos = await supabase.storage.from(_bucket).list(path: uid);
    if (archivos.isEmpty) return;
    await supabase.storage.from(_bucket).remove([for (final a in archivos) '$uid/${a.name}']);
  } catch (_) {}
}
