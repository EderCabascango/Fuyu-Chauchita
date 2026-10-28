# Ingreso por SMS (Supabase Auth)

Maestros y clientes (para reseñar o reportar) entran con su celular y un código SMS.
Supabase no envía SMS por sí solo: hay que conectar un proveedor. **Cada SMS tiene costo**
(pregunta abierta de la especificación: cuál usar).

## Para probar sin pagar SMS

1. Supabase → **Authentication → Sign In / Providers → Phone** → actívalo.
2. Elige un proveedor (por ejemplo Twilio). Si aún no tienes cuenta, igual puedes usar
   **Test Phone Numbers**: en la misma pantalla agrega pares número=código, por ejemplo:

   ```
   593990000001=123456
   ```

   Con ese número la app no envía SMS: el código siempre es `123456`.
   (Si Supabase no deja guardar sin credenciales del proveedor, crea primero la cuenta de prueba
   gratuita del proveedor.)

## Para producción

Opciones comunes que funcionan en Ecuador:

| Proveedor | Notas |
|---|---|
| **Twilio Verify** | El más usado con Supabase. Pago por verificación. |
| **MessageBird / Bird** | Integrado en Supabase. |
| **Vonage** | Integrado en Supabase. |

Pasos generales: crea la cuenta en el proveedor, copia sus credenciales en
**Authentication → Providers → Phone** y guarda. Revisa el precio por SMS a Ecuador (+593).

Recomendado: en **Authentication → Rate Limits** deja un límite razonable de SMS por hora
para evitar abusos que te cuesten dinero.

## Mensajes de error en la app

- "El envío de SMS todavía no está configurado en el servidor": falta el paso de arriba.
- "Demasiados intentos": se alcanzó el límite; esperar un minuto.
