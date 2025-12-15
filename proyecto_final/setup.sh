#!/bin/bash

echo "--- 1. Limpiando ejecutables y logs (MANTENIENDO DATOS) ---"
# Quitamos los .bin del rm para no borrarlos
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

# 1. Archivo de 100MB (Mantener)
if [ -f "datos.bin" ]; then
    echo "✅ 'datos.bin' (100 MB) ya existe. No se toca."
else
    echo "Generando 'datos.bin' (100 MB)..."
    dd if=/dev/urandom of=datos.bin bs=1M count=100 status=progress
fi

# 2. Archivo de 1GB (Nuevo)
if [ -f "datos_1G.bin" ]; then
    echo "✅ 'datos_1G.bin' (1 GB) ya existe. No se toca."
else
    echo "Generando 'datos_1G.bin' (1 GB)..."
    dd if=/dev/urandom of=datos_1G.bin bs=1M count=1024 status=progress
fi

echo "--- ¡TODO LISTO! ---"
echo "Para usar el archivo grande, edita run_benchmark.sh y pon: INPUT=\"datos_1G.bin\""