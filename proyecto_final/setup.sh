#!/bin/bash

echo "--- 1. Limpiando ejecutables y logs (MANTENIENDO DATOS) ---"
# Limpiamos binarios compilados y salidas de slurm, pero NO los .bin de datos
rm -f aes_serial aes_mpi *.out *.err

echo "--- 2. Compilando códigos ---"
module load gnu openmpi 2>/dev/null || echo "Aviso: usando defaults del sistema"

gcc -O3 -o aes_serial aes_serial.c
mpicc -O3 -o aes_mpi aes_mpi.c

if [[ -f "aes_serial" && -f "aes_mpi" ]]; then
    echo "✅ Compilación exitosa."
else
    echo "❌ Error en la compilación."
    exit 1
fi

echo "--- 3. Gestionando Archivos de Datos ---"

# --- Archivo 1: 100 MB ---
if [ -f "datos.bin" ]; then
    echo "✅ 'datos.bin' (100 MB) ya existe. No se toca."
else
    echo "Generando 'datos.bin' (100 MB)..."
    dd if=/dev/urandom of=datos.bin bs=1M count=100 status=progress
fi

# --- Archivo 2: 256 MB (NUEVO) ---
if [ -f "datos_256M.bin" ]; then
    echo "✅ 'datos_256M.bin' (256 MB) ya existe. No se toca."
else
    echo "Generando 'datos_256M.bin' (256 MB)..."
    dd if=/dev/urandom of=datos_256M.bin bs=1M count=256 status=progress
fi

# --- Archivo 3: 512 MB (NUEVO) ---
if [ -f "datos_512M.bin" ]; then
    echo "✅ 'datos_512M.bin' (512 MB) ya existe. No se toca."
else
    echo "Generando 'datos_512M.bin' (512 MB)..."
    dd if=/dev/urandom of=datos_512M.bin bs=1M count=512 status=progress
fi

# --- Archivo 4: 1 GB ---
if [ -f "datos_1G.bin" ]; then
    echo "✅ 'datos_1G.bin' (1 GB) ya existe. No se toca."
else
    echo "Generando 'datos_1G.bin' (1 GB)..."
    dd if=/dev/urandom of=datos_1G.bin bs=1M count=1024 status=progress
fi

echo "--- ¡TODO LISTO! ---"
echo "Archivos disponibles:"
echo " 1. datos.bin      (100 MB)"
echo " 2. datos_256M.bin (256 MB)"
echo " 3. datos_512M.bin (512 MB)"
echo " 4. datos_1G.bin   (1 GB)"