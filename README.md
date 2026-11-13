# Kads Studio · Anuncios con IA

De tu producto a un anuncio listo para Meta y TikTok, en tu propio computador (Mac o Windows).

## Instalar (o actualizar) con un solo comando

### Mac

Abre la **Terminal** (Cmd + Espacio, escribe «Terminal», Enter), pega esto y pulsa Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/kalethabh/kads-studio/main/instalar-mac.sh | bash
```

Queda la aplicación **Kads Studio** en Aplicaciones (búscala con Cmd + Espacio).

### Windows

Abre **PowerShell** (tecla Windows, escribe «PowerShell», Enter), pega esto y pulsa Enter:

```powershell
irm https://raw.githubusercontent.com/kalethabh/kads-studio/main/instalar-windows.ps1 | iex
```

Queda el acceso directo **Kads Studio** en el Escritorio y en el menú Inicio.

## Qué hace el comando

1. Baja la última versión de la app (unos 400 MB) y la deja en tu carpeta de usuario, en «Anuncios con IA».
2. Crea la aplicación «Kads Studio» con su ícono. No pide contraseña ni permisos de administrador.
3. La abre. **La primera vez instala sola lo que le falte a tu computador** (Node.js, ffmpeg y Python, de sus sitios
   oficiales): puede tardar de 10 a 30 minutos. Las veces siguientes abre en segundos.
4. La bienvenida de la app te guía para conectar tu cuenta de Claude y pegar tus claves.

**Para actualizar**, vuelve a pegar el mismo comando: baja la versión nueva sin tocar tus anuncios, tus claves, tus
ajustes ni tus preferencias.

## Lo que necesitas

- **Tu cuenta de Claude** con un plan de pago (Pro o Max), o tu cuenta de ChatGPT.
- **Una clave de kie.ai** con saldo (imágenes, videos y música): https://kie.ai/api-key
- **Una clave de ElevenLabs** (la voz): https://elevenlabs.io/app/settings/api-keys
- **Unos 5 GB libres** en el disco. Mac con macOS 13 (Ventura) o más nuevo; Windows 10 u 11.

Cada persona usa sus propias cuentas y claves, y paga solo lo suyo. Las claves quedan en tu computador.

Mientras uses la app, deja abierta la ventana de texto que se abre con ella. Para cerrar la app, cierra esa ventana.
