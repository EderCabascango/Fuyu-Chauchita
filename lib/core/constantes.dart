/// Nombre visible de la app.
const nombreApp = 'Chauchita';

/// Dirección pública de las páginas de la carpeta `sitio/` (sin "/" al final),
/// por ejemplo 'https://usuario.github.io/chauchita'. Play Store exige la política
/// de privacidad y la página para borrar la cuenta. Vacía = no se muestran los enlaces.
const urlSitio = '';

const urlPrivacidad = urlSitio == '' ? '' : '$urlSitio/privacidad.html';
const urlTerminos = urlSitio == '' ? '' : '$urlSitio/terminos.html';
const urlEliminarCuenta = urlSitio == '' ? '' : '$urlSitio/eliminar-cuenta.html';

/// Correo de soporte que se muestra en la app. Vacío = no se muestra.
const correoSoporte = '';
