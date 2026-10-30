import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';

/// Inicializa Supabase. Llamar una sola vez, al arrancar la app.
Future<void> iniciarSupabase() => Supabase.initialize(
  url: Env.supabaseUrl,
  // Sirve la anon key clásica (eyJ...) o la nueva publishable key (sb_publishable_...).
  publishableKey: Env.supabaseAnonKey,
);

/// Cliente de Supabase listo para usar en cualquier feature.
SupabaseClient get supabase => Supabase.instance.client;
