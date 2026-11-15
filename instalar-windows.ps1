# Kads Studio · instalador para Windows (también actualiza)
#
#   En PowerShell:  irm https://raw.githubusercontent.com/kalethabh/kads-studio/main/instalar-windows.ps1 | iex
#
# Baja la última versión de la app, la deja en tu carpeta de usuario («Anuncios con IA») y crea el acceso directo
# «Kads Studio» en el Escritorio y en el menú Inicio. No pide permisos de administrador. Si ya estaba instalada, la
# actualiza sin tocar lo tuyo: tus anuncios, tus claves, tus ajustes ni tus preferencias.
# Al terminar abre la app; la primera vez instala sola lo que le falte a la PC (Node.js, ffmpeg, Python).

function Instalar-KadsStudio {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'   # sin la barra de progreso de PowerShell la descarga es mucho más rápida
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

  $zipUrl = if ($env:KADS_ZIP_URL) { $env:KADS_ZIP_URL } else { 'https://github.com/kalethabh/kads-studio/releases/latest/download/anuncios-con-ia-app.zip' }
  $destino = if ($env:KADS_DESTINO) { $env:KADS_DESTINO } else { Join-Path $env:USERPROFILE 'Anuncios con IA' }
  $lanzador = 'Abrir Anuncios con IA.bat'

  function Falla($texto) { Write-Host ''; Write-Host " No se pudo instalar: $texto" -ForegroundColor Red; Write-Host ''; throw 'KADS_FALLA' }

  Write-Host ''
  Write-Host " Kads Studio · instalando en «$destino»"
  Write-Host ''
  if ($destino -match 'OneDrive') { Write-Host ' Aviso: esa carpeta está dentro de OneDrive, que puede trabar la app subiendo tus videos.' -ForegroundColor Yellow }

  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('kads-studio-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  try {
    # 1. Bajar la app (unos 400 MB)
    Write-Host ' 1/4  Bajando la app (unos 400 MB, puede tardar unos minutos)...'
    $zip = Join-Path $tmp 'app.zip'
    try {
      if ($zipUrl -like 'file:*') { Copy-Item -LiteralPath ([Uri]$zipUrl).LocalPath -Destination $zip }
      else { Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing }
    } catch { Falla 'no se pudo bajar la app. Revisa tu internet y vuelve a pegar el comando.' }

    # 2. Descomprimir
    Write-Host ' 2/4  Descomprimiendo...'
    $x = Join-Path $tmp 'x'
    try { Expand-Archive -LiteralPath $zip -DestinationPath $x -Force } catch { Falla 'el archivo bajado está dañado. Vuelve a pegar el comando.' }
    $nueva = Join-Path $x 'Anuncios con IA'
    if (-not (Test-Path -LiteralPath (Join-Path $nueva 'VERSION')) -or -not (Test-Path -LiteralPath (Join-Path $nueva $lanzador))) { Falla 'el archivo bajado no es la app. Vuelve a pegar el comando.' }
    $versionNueva = (Get-Content -LiteralPath (Join-Path $nueva 'VERSION') -Raw).Trim()

    # 3. Instalar o actualizar
    if (Test-Path -LiteralPath (Join-Path $destino 'VERSION')) {
      $versionVieja = (Get-Content -LiteralPath (Join-Path $destino 'VERSION') -Raw).Trim()
      Write-Host " 3/4  Ya estaba instalada (versión $versionVieja): actualizando a la $versionNueva sin tocar lo tuyo..."
      # si la app está abierta, se cierra (se vuelve a abrir al final)
      try { Get-NetTCPConnection -LocalPort 4455 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }; Start-Sleep -Seconds 1 } catch {}
      # Lo tuyo nunca se toca (lo mismo que respeta «Actualizar la app»): anuncios, videos, claves, ajustes,
      # preferencias, lo instalado y lo de Claude salvo las skills (que van en una segunda pasada).
      $xd = @('node_modules', '.git') + @('temp', 'output', 'respaldos', '.actualizando', 'mis_archivos', '.claude', 'app\.cache', 'app\capturas', 'remotion\out' | ForEach-Object { Join-Path $destino $_ }) + @('.claude' | ForEach-Object { Join-Path $nueva $_ })
      $xf = @('.env', '.env.local', '.env.*.local', 'Thumbs.db', 'desktop.ini') + @('app\config.json', 'app\.guardado.json', 'app\.guardado-config.json', 'app\server\ocultos.json', 'app\server\muestras-estilos.json' | ForEach-Object { Join-Path $nueva $_ })
      & robocopy $nueva $destino /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP /XD @xd /XF @xf | Out-Null
      if ($LASTEXITCODE -ge 8) { Falla 'no se pudieron copiar los archivos nuevos (¿la app sigue abierta? Ciérrala y vuelve a pegar el comando).' }
      $skills = Join-Path $nueva '.claude\skills'
      if (Test-Path -LiteralPath $skills) {
        & robocopy $skills (Join-Path $destino '.claude\skills') /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { Falla 'no se pudieron copiar las skills nuevas.' }
      }
      # Lo que no existía todavía (por ejemplo, las preferencias en blanco), sin pisar lo que ya tienes
      & robocopy (Join-Path $nueva 'mis_archivos') (Join-Path $destino 'mis_archivos') /E /XC /XN /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
      foreach ($c in 'temp', 'output') { New-Item -ItemType Directory -Path (Join-Path $destino $c) -Force | Out-Null }
      $global:LASTEXITCODE = 0
    } else {
      Write-Host " 3/4  Instalando la versión $versionNueva..."
      if ((Test-Path -LiteralPath $destino) -and (Get-ChildItem -LiteralPath $destino -Force | Select-Object -First 1)) { Falla "ya existe «$destino» y no es la app. Muévela o renómbrala y vuelve a pegar el comando." }
      if (Test-Path -LiteralPath $destino) { Remove-Item -LiteralPath $destino -Force }
      New-Item -ItemType Directory -Path (Split-Path -Parent $destino) -Force | Out-Null
      try { Move-Item -LiteralPath $nueva -Destination $destino } catch { Falla "no pude dejar la carpeta en «$destino»." }
    }
    Get-ChildItem -LiteralPath $destino -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue

    # 4. Los accesos directos «Kads Studio» (con su ícono): Escritorio y menú Inicio
    Write-Host ' 4/4  Creando el acceso directo «Kads Studio»...'
    $ico = Join-Path $destino 'app\kads-studio.ico'
    $png = Join-Path $destino 'app\public\kads-icono-180.png'
    if (Test-Path -LiteralPath $png) {
      # un .ico con el PNG adentro (lo entiende Windows desde Vista)
      $b = [IO.File]::ReadAllBytes($png)
      $ms = New-Object IO.MemoryStream
      $w = New-Object IO.BinaryWriter($ms)
      $w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]1)
      $w.Write([Byte]180); $w.Write([Byte]180); $w.Write([Byte]0); $w.Write([Byte]0)
      $w.Write([UInt16]1); $w.Write([UInt16]32); $w.Write([UInt32]$b.Length); $w.Write([UInt32]22)
      $w.Write($b); $w.Flush()
      [IO.File]::WriteAllBytes($ico, $ms.ToArray())
    }
    $shell = New-Object -ComObject WScript.Shell
    $inicio = Join-Path ([Environment]::GetFolderPath('Programs')) 'Kads Studio.lnk'
    $escritorio = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Kads Studio.lnk'
    foreach ($ruta in $inicio, $escritorio) {
      if (-not (Test-Path -LiteralPath (Split-Path -Parent $ruta))) { continue }
      $s = $shell.CreateShortcut($ruta)
      $s.TargetPath = Join-Path $destino $lanzador
      $s.WorkingDirectory = $destino
      $s.Description = 'Kads Studio · anuncios con IA'
      if (Test-Path -LiteralPath $ico) { $s.IconLocation = "$ico,0" }
      $s.Save()
    }

    Write-Host ''
    Write-Host " Listo: Kads Studio $versionNueva quedó instalada." -ForegroundColor Green
    Write-Host '   · La app: «Kads Studio» en tu Escritorio y en el menú Inicio.'
    Write-Host "   · Tus anuncios y la app: «$destino»."
    Write-Host '   · Para actualizar más adelante, vuelve a pegar este mismo comando.'
    Write-Host ''
    if (-not $env:KADS_NO_ABRIR) {
      Write-Host ' Abriendo Kads Studio... La primera vez instala lo que falte (puede tardar de 10 a 30 minutos).'
      Start-Process -FilePath (Join-Path $destino $lanzador) -WorkingDirectory $destino
    }
  } catch {
    if ($_.Exception.Message -ne 'KADS_FALLA') { Write-Host ''; Write-Host " No se pudo instalar: $($_.Exception.Message)" -ForegroundColor Red; Write-Host '' }
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
Instalar-KadsStudio
