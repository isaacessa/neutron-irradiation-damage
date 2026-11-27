# ============================================================
# 1. DIRECTORIO GENERAL DE LA BIBLIOTECA Lib80x
# ============================================================

# Ruta principal donde se encuentra la biblioteca Lib80x
$directorioDatos = "C:\MCNP_DATA"
$lib80x = Join-Path $directorioDatos "Lib80x"

# Comprobar que la biblioteca existe
if (-not (Test-Path $lib80x)) {
    Write-Host ""
    Write-Host "No se encontro la biblioteca Lib80x:"
    Write-Host $lib80x
    exit
}


# ============================================================
# 2. TEMPERATURA DE TRABAJO
# ============================================================

# Para esta primera version del programa se utilizaran
# solamente las tablas procesadas a temperatura ambiente.
#
# En Lib80x:
#
# .00c = 293.6 K
#
# Las demas temperaturas no se consideraran por el momento.

$sufijoTemperatura = ".00c"
$temperaturaK = 293.6


# ============================================================
# 3. SELECCIONAR EL ELEMENTO
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " SELECCION DE ELEMENTO"
Write-Host "========================================"
Write-Host ""

$elemento = Read-Host "Teclea el simbolo del elemento (ej. Fe, Cr, Ti, W)"


# Construir la ruta correspondiente al elemento seleccionado
$carpetaElemento = Join-Path $lib80x $elemento


# Comprobar que existe una carpeta para ese elemento
if (-not (Test-Path $carpetaElemento)) {

    Write-Host ""
    Write-Host "No se encontro el elemento $elemento en Lib80x."
    Write-Host "Ruta buscada:"
    Write-Host $carpetaElemento
    exit
}


# ============================================================
# 4. MOSTRAR SELECCION DEL ELEMENTO
# ============================================================

Write-Host ""
Write-Host "Elemento seleccionado : $elemento"
Write-Host "Temperatura            : $temperaturaK K"
Write-Host "Sufijo MCNP            : $sufijoTemperatura"
Write-Host "Carpeta                : $carpetaElemento"
Write-Host ""

# ============================================================
# 5. LEER EL ARCHIVO xsdir
# ============================================================

# Ruta del archivo xsdir de Lib80x
$archivoXsdir = Join-Path $directorioDatos "xsdir"

# Comprobar que xsdir existe
if (-not (Test-Path $archivoXsdir)) {

    Write-Host ""
    Write-Host "No se encontro el archivo xsdir:"
    Write-Host $archivoXsdir
    exit
}


# ============================================================
# 6. BUSCAR TABLAS DEL ELEMENTO A TEMPERATURA AMBIENTE
# ============================================================

# Aqui se guardaran las tablas encontradas
$tablasDisponibles = @()

# Leer xsdir linea por linea
foreach ($linea in Get-Content $archivoXsdir) {

    # Eliminar espacios al inicio y separar la linea en campos
    $campos = $linea.Trim() -split '\s+'

    # Una entrada valida de xsdir debe tener varios campos.
    # Para nuestra busqueda necesitamos al menos:
    #
    # campo 0 -> nombre de la tabla MCNP
    # campo 2 -> ruta del archivo ACE

    if ($campos.Count -lt 3) {
        continue
    }

    $nombreTabla = $campos[0]
    $rutaACE     = $campos[2]


    # Comprobar que:
    #
    # 1. El primer campo tiene la forma de una tabla de neutrones
    #    (por ejemplo 26056.00c)
    #
    # 2. Corresponde a temperatura ambiente (.00c)
    #
    # 3. La ruta pertenece al elemento seleccionado

    if (
        ($nombreTabla -match '^\d+\.\d+c$') -and
        ($nombreTabla.EndsWith($sufijoTemperatura)) -and
        ($rutaACE -match "[\\/]$([regex]::Escape($elemento))[\\/]")
    ) {

        # ZAID = parte anterior al punto
        $zaidTabla = [long]($nombreTabla.Split('.')[0])

        # En un ZAID convencional:
        # ZAID = 1000*Z + A
        # Por lo tanto, el residuo entre 1000 corresponde a A.
        $numeroMasico = $zaidTabla % 1000

        # Guardar toda la informacion que necesitaremos despues
        $tablasDisponibles += [PSCustomObject]@{
            Isotopo = "$elemento-$numeroMasico"
            Tabla   = $nombreTabla
            RutaACE = $rutaACE
        }
    }
}


# ============================================================
# 7. MOSTRAR LAS TABLAS DISPONIBLES
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " TABLAS DISPONIBLES A 293.6 K"
Write-Host "========================================"
Write-Host ""

if ($tablasDisponibles.Count -eq 0) {

    Write-Host "No se encontraron tablas .00c para $elemento."
    exit
}

foreach ($tabla in $tablasDisponibles) {

    Write-Host "$($tabla.Isotopo)"
    Write-Host "  Tabla MCNP : $($tabla.Tabla)"
    Write-Host "  Archivo ACE: $($tabla.RutaACE)"
    Write-Host ""
}

# ============================================================
# 8. SELECCIONAR UN ISOTOPO
# ============================================================

Write-Host "========================================"
Write-Host " SELECCION DE ISOTOPO"
Write-Host "========================================"
Write-Host ""

# Mostrar una lista numerada de los isotopos disponibles
for ($i = 0; $i -lt $tablasDisponibles.Count; $i++) {

    $numeroOpcion = $i + 1
    $tabla = $tablasDisponibles[$i]

    Write-Host "[$numeroOpcion] $($tabla.Isotopo)"
}

Write-Host ""

[int]$seleccion = Read-Host "Selecciona el numero del isotopo"


# ============================================================
# 9. VALIDAR LA SELECCION
# ============================================================

if (
    ($seleccion -lt 1) -or
    ($seleccion -gt $tablasDisponibles.Count)
) {

    Write-Host ""
    Write-Host "Seleccion no valida."
    exit
}

# ============================================================
# 10. CONSTRUIR LA RUTA DE LA TABLA ACE
# ============================================================

# PowerShell empieza a contar desde 0,
# por eso restamos 1 a la opcion elegida.

$tablaSeleccionada = $tablasDisponibles[$seleccion - 1]

$isotopoSeleccionado = $tablaSeleccionada.Isotopo
$nombreTablaMCNP     = $tablaSeleccionada.Tabla
$rutaRelativaACE     = $tablaSeleccionada.RutaACE


# Construir la ruta completa al archivo ACE
$rutaACEWindows = $rutaRelativaACE -replace '/', '\'

$archivo = Join-Path $directorioDatos $rutaACEWindows

# Comprobar que el archivo ACE seleccionado existe
if (-not (Test-Path -LiteralPath $archivo -PathType Leaf)) {

    Write-Host ""
    Write-Host "No se encontro el archivo ACE seleccionado:"
    Write-Host $archivo
    exit
}


# ============================================================
# 11. MOSTRAR LA SELECCION LA TABLA SELECCIONADA
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " TABLA SELECCIONADA"
Write-Host "========================================"
Write-Host ""

Write-Host "Isotopo            : $isotopoSeleccionado"
Write-Host "Tabla MCNP         : $nombreTablaMCNP"
Write-Host "Archivo ACE        : $archivo"
Write-Host ""

# ============================================================
# 12. LEER EL ENCABEZADO DE LA TABLA ACE
# ============================================================

# Primero se leen únicamente las dos primeras líneas del archivo.
# La segunda línea contiene el número de líneas de comentarios,
# necesario para determinar la posición de los arreglos
# IZAW, NXS y JXS dentro del preámbulo.

$encabezado = Get-Content -Path $archivo -TotalCount 2


# ============================================================
# 13. INTERPRETAR EL ENCABEZADO DE LA TABLA ACE
# ============================================================

# Primera línea del encabezado:
#
# 2.0.1   26056.800nc   ENDF/B-VIII.0

$linea1 = $encabezado[0].Trim() -split '\s+'

$versionACE = $linea1[0]
$tablaACE   = $linea1[1]
$biblioteca = $linea1[2]


# Segunda línea del encabezado:
#
# 55.454430   2.5301e-08   2018-05-01   2
#
# El cuarto valor indica el número de líneas de comentarios
# presentes después del encabezado.

$linea2 = $encabezado[1].Trim() -split '\s+'

$awr          = $linea2[0]
$temperatura  = $linea2[1]
$fecha        = $linea2[2]
$nComentarios = [int]$linea2[3]


# ============================================================
# 14. CALCULAR LA ESTRUCTURA DEL PREAMBULO
# ============================================================

# Después de las dos líneas del encabezado aparecen:
#
# - nComentarios líneas de comentarios
# - 4 líneas correspondientes a IZAW
# - 2 líneas correspondientes a NXS
# - 4 líneas correspondientes a JXS
#
# Como PowerShell numera los arreglos comenzando desde 0,
# se calculan automáticamente las posiciones de cada bloque.

$inicioIZAW = 2 + $nComentarios

$inicioNXS = $inicioIZAW + 4
$finNXS    = $inicioNXS + 1

$inicioJXS = $finNXS + 1
$finJXS    = $inicioJXS + 3

# El arreglo XSS comienza inmediatamente después de JXS.
# Este valor también corresponde al número total de líneas
# que forman el preámbulo.

$inicioXSS = $finJXS + 1


# Leer ahora el preámbulo completo utilizando el número
# de líneas calculado automáticamente.

$preambulo = Get-Content -Path $archivo -TotalCount $inicioXSS


# ============================================================
# 15. LEER EL ARREGLO NXS
# ============================================================

# El arreglo NXS contiene 16 valores enteros distribuidos
# en dos líneas consecutivas del archivo ACE.
#
# Las posiciones de esas líneas ya no se escriben manualmente,
# sino que se obtienen a partir del número de comentarios
# indicado en el encabezado.

$nxsTexto = (
    $preambulo[$inicioNXS..$finNXS] -join " "
).Trim() -split '\s+'

# Convertir los valores de texto a números enteros.
[long[]]$NXS = $nxsTexto


# ============================================================
# 16. EXTRAER LA INFORMACION DE NXS
# ============================================================

# La documentación ACE numera NXS desde 1:
#
# NXS(1) = tamaño total de XSS
# NXS(2) = ZAID
# NXS(3) = número de puntos de energía
# NXS(4) = número de entradas del bloque MTR
#
# PowerShell numera los arreglos desde 0:
#
# NXS(1) -> $NXS[0]
# NXS(2) -> $NXS[1]
# NXS(3) -> $NXS[2]
# NXS(4) -> $NXS[3]

$tamanoXSS     = $NXS[0]
$zaid          = $NXS[1]
$puntosEnergia = $NXS[2]
$numeroMT      = $NXS[3]
# ============================================================
# 17. LEER EL ARREGLO JXS
# ============================================================

# El arreglo JXS contiene 32 valores enteros.
# En el archivo ACE se distribuye en cuatro líneas,
# con ocho valores por línea.
#
# Estas cuatro líneas forman un único arreglo:
#
# JXS(1), JXS(2), ..., JXS(32)

$jxsTexto = (
    $preambulo[$inicioJXS..$finJXS] -join " "
).Trim() -split '\s+'

# Convertir los valores de texto a números enteros
[long[]]$JXS = $jxsTexto

# ============================================================
# 18. LOCALIZAR EL BLOQUE MTR
# ============================================================

# La documentación ACE numera JXS desde 1:
#
# JXS(3) = posición de XSS donde comienza MTR
# JXS(4) = posición de XSS donde comienza LQR
#
# PowerShell comienza a contar desde 0:
#
# JXS(3) -> $JXS[2]
# JXS(4) -> $JXS[3]

$inicioMTR = $JXS[2]
$inicioLQR = $JXS[3]

# Ya conocemos el número de entradas de MTR gracias a NXS(4).
# Por tanto, podemos calcular dónde termina MTR.

$finMTR = $inicioMTR + $numeroMT - 1

# ============================================================
# 19. MOSTRAR INFORMACIÓN  DE LA TABLA ACE
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " INFORMACION DE LA TABLA ACE"
Write-Host "========================================"
Write-Host ""

Write-Host "Version ACE       : $versionACE"
Write-Host "Tabla ACE         : $tablaACE"
Write-Host "Biblioteca origen : $biblioteca"
Write-Host "AWR               : $awr"
Write-Host "Temperatura kT    : $temperatura MeV"
Write-Host "Fecha             : $fecha"
Write-Host "Comentarios       : $nComentarios"

Write-Host ""

# ============================================================
# 20. MOSTRAR ESTRUCTURA DE LOS NUMEROS MT
# ============================================================

Write-Host "========================================"
Write-Host " ESTRUCTURA PARA LOS NUMEROS MT"
Write-Host "========================================"
Write-Host ""

Write-Host "Tamano de XSS       : $tamanoXSS"
Write-Host "ZAID                : $zaid"
Write-Host "Puntos de energia   : $puntosEnergia"
Write-Host "Numero de MT        : $numeroMT"

Write-Host ""

Write-Host "Inicio de MTR       : XSS($inicioMTR)"
Write-Host "Fin de MTR          : XSS($finMTR)"
Write-Host "Inicio de LQR       : XSS($inicioLQR)"

Write-Host ""

# ============================================================
# 21. SOLICITAR EL NUMERO MT A BUSCAR
# ============================================================

Write-Host "========================================"
Write-Host " BUSQUEDA DE NUMERO MT"
Write-Host "========================================"
Write-Host ""

[int]$mtBuscado = Read-Host "Teclea el numero MT que deseas buscar"

Write-Host ""
Write-Host "MT solicitado       : $mtBuscado"
Write-Host ""

# ============================================================
# 22. LEER EL BLOQUE MTR DENTRO DE XSS
# ============================================================

# Variable que indicará si el MT solicitado fue encontrado
$mtEncontrado = $false

# Guardaremos también la posición de XSS donde fue encontrado
$posicionMT = $null

# Abrir el archivo ACE para leerlo línea por línea
$lector = [System.IO.StreamReader]::new($archivo)

try {

    # --------------------------------------------------------
    # Saltar el preámbulo
    # --------------------------------------------------------
    #
    # El preambulo de la tabla ACE contiene:
    #
    # - Encabezado ACE
    # - Lineas de comentarios
    # - Arreglo IZAW
    # - Arreglo NXS
    # - Arreglo JXS
    #
    # Después de este preambulo comienza el arreglo XSS.
    #
    # NOTA:
    # El número de líneas del preámbulo se determina
    # automáticamente a partir de la estructura del
    # encabezado ACE.

    for ($i = 0; $i -lt $inicioXSS; $i++) {
        [void]$lector.ReadLine()
    }


    # --------------------------------------------------------
    # Recorrer los valores de XSS
    # --------------------------------------------------------

    # ACE numera XSS comenzando en 1
    $posicionXSS = 0

    while (($linea = $lector.ReadLine()) -ne $null) {

        # Cada línea puede contener varios valores de XSS
        $valores = $linea.Trim() -split '\s+'

        foreach ($texto in $valores) {

            if ([string]::IsNullOrWhiteSpace($texto)) {
                continue
            }

            # Avanzar una posición dentro del arreglo XSS
            $posicionXSS++


            # ------------------------------------------------
            # Revisar únicamente el intervalo correspondiente
            # al bloque MTR
            # ------------------------------------------------

            if (($posicionXSS -ge $inicioMTR) -and
                ($posicionXSS -le $finMTR)) {

                # Los valores de XSS están escritos como números
                # reales, por lo que primero se interpretan como
                # Double y después como entero para el número MT.

                $valorXSS = [double]::Parse(
                    $texto,
                    [System.Globalization.CultureInfo]::InvariantCulture
                )

                $valorMT = [int]$valorXSS


                # Comparar con el MT solicitado por el usuario
                if ($valorMT -eq $mtBuscado) {

                    $mtEncontrado = $true
                    $posicionMT = $posicionXSS
                }
            }


            # Una vez alcanzado el final de MTR ya no necesitamos
            # seguir leyendo los millones de valores restantes.

            if ($posicionXSS -ge $finMTR) {
                break
            }
        }

        if ($posicionXSS -ge $finMTR) {
            break
        }
    }
}
finally {

    # Cerrar el archivo aunque ocurra algún error
    $lector.Close()
}

# ============================================================
# 23. MOSTRAR RESULTADO DE LA BÚSQUEDA
# ============================================================

Write-Host "Intervalo analizado : XSS($inicioMTR) - XSS($finMTR)"
Write-Host ""

# ============================================================
# 24. MOSTRAR RESULTADO DE LA BÚSQUEDA
# ============================================================

Write-Host "Intervalo analizado : XSS($inicioMTR) - XSS($finMTR)"
Write-Host ""

if ($mtEncontrado) {

    $posicionMTR = $posicionMT - $inicioMTR + 1

    Write-Host "MT $mtBuscado encontrado."
    Write-Host "Posicion en XSS     : XSS($posicionMT)"
    Write-Host "Posicion en MTR     : MTR($posicionMTR)"

} else {

    Write-Host "MT $mtBuscado no encontrado en el bloque MTR."
}

Write-Host ""