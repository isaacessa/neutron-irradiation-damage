# ============================================================
# VERIFICACIÓN SISTEMÁTICA DE MT=444
# EN LA BIBLIOTECA HDF5 DE OPENMC
# ============================================================

import openmc
import openmc.data

from pathlib import Path


# ============================================================
# 0. NUCLEIDOS QUE SE DESEAN ANALIZAR
#
# Se utilizan los mismos nucleidos revisados previamente
# en las tablas ACE de Lib80x para MCNP.
#
# Los nombres siguen la convención GNDS utilizada por OpenMC:
#
#       símbolo químico + número másico
#
# Por ejemplo:
#
#       Fe56  ->  Fe-56
#       Cr52  ->  Cr-52
#       W184  ->  W-184
# ============================================================

nucleidos = {
    "Fe": ["Fe54", "Fe55", "Fe56", "Fe57", "Fe58"],
    "Cr": ["Cr50", "Cr51", "Cr52", "Cr53", "Cr54"],
    "W":  ["W180", "W181", "W182", "W183", "W184", "W185", "W186"],
    "Ti": ["Ti46", "Ti47", "Ti48", "Ti49", "Ti50"],
    "Y":  ["Y89", "Y90", "Y91"],
    "O":  ["O16", "O17", "O18"]
}


# ------------------------------------------------------------
# 1. Mostrar la versión de OpenMC
# ------------------------------------------------------------

print("Versión de OpenMC:")
print(openmc.__version__)


# ------------------------------------------------------------
# 2. Localizar el archivo cross_sections.xml
#
# Este archivo actúa como índice de la biblioteca HDF5
# disponible para OpenMC.
# ------------------------------------------------------------

ruta_cross_sections = openmc.config.get("cross_sections")

# Comprobar que existe una biblioteca configurada
if ruta_cross_sections is None:
    raise RuntimeError(
        "No se ha configurado la biblioteca de datos nucleares de OpenMC."
    )

# Comprobar que el archivo XML existe
if not Path(ruta_cross_sections).is_file():
    raise FileNotFoundError(
        f"No se encontró el archivo: {ruta_cross_sections}"
    )

print("\nArchivo cross_sections.xml:")
print(ruta_cross_sections)


# ------------------------------------------------------------
# 3. Leer la biblioteca de datos nucleares
#
# DataLibrary interpreta cross_sections.xml y permite
# localizar el archivo HDF5 correspondiente a cada nucleido.
# ------------------------------------------------------------

biblioteca = openmc.data.DataLibrary.from_xml(ruta_cross_sections)


# ============================================================
# 4. RECORRER LOS NUCLEIDOS
# ============================================================

# Aquí guardaremos los resultados para poder mostrarlos
# posteriormente en forma de tabla.

resultados = []


for elemento, lista_nucleidos in nucleidos.items():

    for nucleido in lista_nucleidos:

        # ----------------------------------------------------
        # 4.1. Buscar el nucleido en cross_sections.xml
        # ----------------------------------------------------

        entrada = biblioteca.get_by_material(nucleido)


        # ----------------------------------------------------
        # 4.2. Comprobar que el nucleido existe
        # ----------------------------------------------------

        if entrada is None:

            resultados.append({
                "elemento": elemento,
                "nucleido": nucleido,
                "archivo": "---",
                "mt444": "No disponible",
                "temperaturas": "---"
            })

            continue


        # ----------------------------------------------------
        # 4.3. Obtener la ruta del archivo HDF5
        # ----------------------------------------------------

        ruta_hdf5 = entrada["path"]


        # Extraemos únicamente el nombre del archivo.
        #
        # Ejemplo:
        #
        # /ruta/biblioteca/neutron/Fe56.h5
        #
        # se convierte en:
        #
        # Fe56.h5

        nombre_archivo = Path(ruta_hdf5).name


        # ----------------------------------------------------
        # 4.4. Leer los datos nucleares del nucleido
        # ----------------------------------------------------

        datos = openmc.data.IncidentNeutron.from_hdf5(ruta_hdf5)


        # ----------------------------------------------------
        # 4.5. Buscar específicamente MT = 444
        # ----------------------------------------------------

        if 444 in datos.reactions:

            reaccion_444 = datos.reactions[444]

            # Temperaturas para las que existe MT=444

            temperaturas = sorted(
                reaccion_444.xs.keys(),
                key=lambda t: float(t.rstrip("K"))
            )

            # Convertimos la lista en texto para imprimirla
            # posteriormente dentro de la tabla.

            temperaturas_texto = ", ".join(temperaturas)

            mt444 = "Sí"

        else:

            temperaturas_texto = "---"

            mt444 = "No"


        # ----------------------------------------------------
        # 4.6. Guardar el resultado del nucleido
        # ----------------------------------------------------

        resultados.append({
            "elemento": elemento,
            "nucleido": nucleido,
            "archivo": nombre_archivo,
            "mt444": mt444,
            "temperaturas": temperaturas_texto
        })


# ============================================================
# 5. MOSTRAR LOS RESULTADOS
# ============================================================

print("\n")
print("=" * 100)
print("VERIFICACIÓN DE MT=444 EN LA BIBLIOTECA HDF5 DE OPENMC")
print("=" * 100)

print(
    f"{'Elemento':<10}"
    f"{'Nucleido':<12}"
    f"{'Archivo HDF5':<18}"
    f"{'MT=444':<18}"
    f"{'Temperaturas'}"
)

print("-" * 100)


for resultado in resultados:

    print(
        f"{resultado['elemento']:<10}"
        f"{resultado['nucleido']:<12}"
        f"{resultado['archivo']:<18}"
        f"{resultado['mt444']:<18}"
        f"{resultado['temperaturas']}"
    )


print("=" * 100)