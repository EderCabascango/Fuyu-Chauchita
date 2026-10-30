// Edge Function "notificar": envía notificaciones push (Firebase Cloud Messaging)
// cuando un Database Webhook de Supabase avisa de:
//   - profesionales UPDATE: el perfil pasó a "aprobado"
//   - resenas INSERT: el profesional recibió una reseña
//
// Secretos necesarios (ver docs/NOTIFICACIONES.md):
//   FCM_SERVICE_ACCOUNT  JSON de la cuenta de servicio de Firebase
//   WEBHOOK_SECRET       texto aleatorio; el webhook lo manda en el header x-webhook-secret
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los pone Supabase automáticamente.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { JWT } from "npm:google-auth-library@9.14.1";

type Payload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
};

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const cuenta = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
const jwt = new JWT({
  email: cuenta.client_email,
  key: cuenta.private_key,
  scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
});

Deno.serve(async (req) => {
  if (!secretoValido(req.headers.get("x-webhook-secret"))) {
    return new Response("No autorizado", { status: 401 });
  }
  if (req.method !== "POST") return new Response("Método no permitido", { status: 405 });

  const p = (await req.json()) as Payload;
  const aviso = await armarAviso(p);
  if (!aviso) return Response.json({ enviado: 0, motivo: "evento sin aviso" });

  const { data: dispositivos } = await supabase
    .from("dispositivos")
    .select("token")
    .eq("usuario_id", aviso.usuarioId);

  let enviados = 0;
  for (const { token } of dispositivos ?? []) {
    if (await enviar(token, aviso.titulo, aviso.cuerpo)) enviados++;
  }
  return Response.json({ enviado: enviados });
});

async function armarAviso(p: Payload) {
  if (p.table === "profesionales" && p.type === "UPDATE") {
    const antes = p.old_record?.estado;
    const ahora = p.record?.estado;
    if (antes !== "aprobado" && ahora === "aprobado") {
      return {
        usuarioId: p.record!.usuario_id as string,
        titulo: "¡Tu perfil fue aprobado!",
        cuerpo: "Ya apareces en Oficios Cayambe. Activa \"Disponible ahora\" cuando puedas atender.",
      };
    }
    return null;
  }

  if (p.table === "resenas" && p.type === "INSERT") {
    const { data: prof } = await supabase
      .from("profesionales")
      .select("usuario_id")
      .eq("id", p.record!.profesional_id as string)
      .single();
    if (!prof) return null;
    const estrellas = Number(p.record!.estrellas);
    return {
      usuarioId: prof.usuario_id as string,
      titulo: "Recibiste una reseña nueva",
      cuerpo: `Un cliente te calificó con ${estrellas} ${estrellas === 1 ? "estrella" : "estrellas"}.`,
    };
  }

  return null;
}

/** Devuelve true si se envió. Borra el token si Firebase dice que ya no existe. */
async function enviar(token: string, titulo: string, cuerpo: string): Promise<boolean> {
  const { token: acceso } = await jwt.getAccessToken();
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${cuenta.project_id}/messages:send`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${acceso}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: titulo, body: cuerpo },
          android: { priority: "high" },
        },
      }),
    },
  );
  if (res.ok) return true;

  const error = await res.text();
  if (res.status === 404 || error.includes("UNREGISTERED")) {
    await supabase.from("dispositivos").delete().eq("token", token);
  } else {
    console.error("FCM", res.status, error);
  }
  return false;
}

/// Compara el secreto en tiempo constante (no revela cuántas letras acertó).
function secretoValido(recibido: string | null): boolean {
  const esperado = Deno.env.get("WEBHOOK_SECRET") ?? "";
  if (esperado.length < 16 || recibido === null) return false;
  const a = new TextEncoder().encode(recibido);
  const b = new TextEncoder().encode(esperado);
  let diferencia = a.length ^ b.length;
  for (let i = 0; i < b.length; i++) diferencia |= (a[i] ?? 0) ^ b[i];
  return diferencia === 0;
}
