#!/bin/bash
# Kads Studio · instalador para Mac (también actualiza)
#
#   curl -fsSL https://raw.githubusercontent.com/kalethabh/kads-studio/main/instalar-mac.sh | bash
#
# Baja la última versión de la app, la deja en tu carpeta de usuario («Anuncios con IA») y crea la aplicación
# «Kads Studio» en Aplicaciones (en tu carpeta de usuario: no pide contraseña). Si ya estaba instalada, la
# actualiza sin tocar lo tuyo: tus anuncios, tus claves, tus ajustes ni tus preferencias.
# Al terminar abre la app; la primera vez instala sola lo que le falte a la Mac (Node.js, ffmpeg, Python).

ZIP_URL="${KADS_ZIP_URL:-https://github.com/kalethabh/kads-studio/releases/latest/download/anuncios-con-ia-app.zip}"
DESTINO="${KADS_DESTINO:-$HOME/Anuncios con IA}"
APLICACION="${KADS_APLICACION:-$HOME/Applications/Kads Studio.app}"
LANZADOR="Abrir Anuncios con IA.command"

falla() { echo; echo " No se pudo instalar: $1"; echo; exit 1; }

[ "$(uname -s)" = "Darwin" ] || falla "este instalador es para Mac. En Windows usa el comando de PowerShell."
echo
echo " Kads Studio · instalando en «${DESTINO}»"
echo

TMP="$(mktemp -d "${TMPDIR:-/tmp}/kads-studio.XXXXXX")" || falla "no pude crear una carpeta temporal."
trap 'rm -rf "$TMP"' EXIT

# 1. Bajar la app (unos 400 MB)
echo " 1/4  Bajando la app..."
curl -fL --retry 3 --progress-bar "${ZIP_URL}" -o "$TMP/app.zip" || falla "no se pudo bajar la app. Revisa tu internet y vuelve a pegar el comando."

# 2. Descomprimir (ditto es el descompresor de la Mac: respeta tildes, espacios y los permisos de los lanzadores)
echo " 2/4  Descomprimiendo..."
mkdir -p "$TMP/x" && ditto -x -k "$TMP/app.zip" "$TMP/x" || falla "el archivo bajado está dañado. Vuelve a pegar el comando."
NUEVA="$TMP/x/Anuncios con IA"
[ -f "$NUEVA/VERSION" ] && [ -f "$NUEVA/${LANZADOR}" ] || falla "el archivo bajado no es la app. Vuelve a pegar el comando."
VERSION_NUEVA="$(tr -d '[:space:]' < "$NUEVA/VERSION")"

# 3. Instalar o actualizar
if [ -f "${DESTINO}/VERSION" ]; then
  echo " 3/4  Ya estaba instalada (versión $(tr -d '[:space:]' < "${DESTINO}/VERSION")): actualizando a la ${VERSION_NUEVA} sin tocar lo tuyo..."
  # Si la app está abierta, se cierra (se vuelve a abrir al final)
  lsof -ti tcp:4455 -sTCP:LISTEN 2>/dev/null | xargs kill 2>/dev/null; sleep 1
  # Lo tuyo nunca se toca (lo mismo que respeta «Actualizar la app»): anuncios, videos, claves, ajustes,
  # preferencias, lo instalado y lo de Claude salvo las skills.
  rsync -a \
    --exclude='/temp/' --exclude='/output/' --exclude='/respaldos/' --exclude='/.actualizando/' --exclude='/.git/' \
    --exclude='/mis_archivos/' --exclude='node_modules/' --include='/.env.example' --exclude='.env' --exclude='.env.*' \
    --exclude='/app/config.json' --exclude='/app/.cache/' --exclude='/app/capturas/' --exclude='/remotion/out/' \
    --exclude='/app/.guardado.json' --exclude='/app/.guardado-config.json' \
    --exclude='/app/server/ocultos.json' --exclude='/app/server/muestras-estilos.json' \
    --include='/.claude/' --include='/.claude/skills/***' --exclude='/.claude/*' \
    "$NUEVA/" "${DESTINO}/" || falla "no se pudieron copiar los archivos nuevos."
  # Lo que no existía todavía (por ejemplo, las preferencias en blanco), sin pisar lo que ya tienes
  rsync -a --ignore-existing "$NUEVA/mis_archivos/" "${DESTINO}/mis_archivos/" 2>/dev/null
  mkdir -p "${DESTINO}/temp" "${DESTINO}/output"
else
  echo " 3/4  Instalando la versión ${VERSION_NUEVA}..."
  [ -e "${DESTINO}" ] && [ -n "$(ls -A "${DESTINO}" 2>/dev/null)" ] && falla "ya existe «${DESTINO}» y no es la app. Muévela o renómbrala y vuelve a pegar el comando."
  mkdir -p "$(dirname "${DESTINO}")" && rm -rf "${DESTINO}" && mv "$NUEVA" "${DESTINO}" || falla "no pude dejar la carpeta en «${DESTINO}»."
fi
chmod +x "${DESTINO}/${LANZADOR}"
xattr -dr com.apple.quarantine "${DESTINO}" 2>/dev/null

# 4. La aplicación «Kads Studio» (con su ícono), en Aplicaciones de tu carpeta de usuario
echo " 4/4  Creando la aplicación «Kads Studio»..."
rm -rf "${APLICACION}"
mkdir -p "${APLICACION}/Contents/MacOS" "${APLICACION}/Contents/Resources"
cat > "${APLICACION}/Contents/MacOS/kads-studio" <<APP
#!/bin/bash
# Abre Kads Studio: su lanzador en una ventana de Terminal (déjala abierta mientras usas la app).
CARPETA="${DESTINO}"
if [ ! -f "\${CARPETA}/${LANZADOR}" ]; then
  osascript -e 'display alert "Kads Studio" message "No encuentro la carpeta de la app («'"\${CARPETA}"'»). Vuelve a pegar el comando de instalación."'
  exit 1
fi
open -a Terminal "\${CARPETA}/${LANZADOR}"
APP
chmod +x "${APLICACION}/Contents/MacOS/kads-studio"
cat > "${APLICACION}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Kads Studio</string>
  <key>CFBundleDisplayName</key><string>Kads Studio</string>
  <key>CFBundleIdentifier</key><string>com.kalethabh.kads-studio</string>
  <key>CFBundleVersion</key><string>${VERSION_NUEVA}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION_NUEVA}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>kads-studio</string>
  <key>CFBundleIconFile</key><string>kads</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
PLIST
ICONO="${DESTINO}/app/public/kads-icono-512.png"
if [ -f "$ICONO" ]; then
  SET="$TMP/kads.iconset"; mkdir -p "$SET"
  for t in 16 32 128 256 512; do
    sips -z $t $t "$ICONO" --out "$SET/icon_${t}x${t}.png" >/dev/null 2>&1
    d=$((t * 2)); [ $d -le 512 ] && sips -z $d $d "$ICONO" --out "$SET/icon_${t}x${t}@2x.png" >/dev/null 2>&1
  done
  iconutil -c icns "$SET" -o "${APLICACION}/Contents/Resources/kads.icns" 2>/dev/null
fi
touch "${APLICACION}"
# Que el Finder y el Launchpad la vean ya
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${APLICACION}" >/dev/null 2>&1

echo
echo " Listo: Kads Studio ${VERSION_NUEVA} quedó instalada."
echo "   · La app: «Kads Studio» en Aplicaciones (Finder → Ir → Inicio → Aplicaciones, o búscala con Cmd+Espacio)."
echo "   · Tus anuncios y la app: «${DESTINO}»."
echo "   · Para actualizar más adelante, vuelve a pegar este mismo comando."
echo
if [ -z "$KADS_NO_ABRIR" ]; then
  echo " Abriendo Kads Studio... La primera vez instala lo que falte (puede tardar de 10 a 30 minutos)."
  open "${APLICACION}"
fi
