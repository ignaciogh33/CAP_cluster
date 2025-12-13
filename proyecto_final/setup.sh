#!/bin/bash

echo "--- 1. Limpiando entorno ---"
rm -f aes_serial aes_mpi datos.bin *.out

echo "--- 2. Compilando códigos ---"
# Cargamos módulos si es necesario (común en OpenHPC)
module load gnu openmpi 2>/dev/null || echo "Aviso: No se pudieron cargar módulos, intentando usar defaults del sistema"

# Compilación
gcc -O3 -o aes_serial aes_serial.c
mpicc -O3 -o aes_mpi aes_mpi.c

if [[ -f "aes_serial" && -f "aes_mpi" ]]; then
    echo "✅ Compilación exitosa."
else
    echo "❌ Error en la compilación."
    exit 1
fi

echo "--- 3. Generando datos de prueba (100 MB) ---"
# Usamos /dev/urandom para crear 100MB de datos aleatorios binarios
dd if=/dev/urandom of=datos.bin bs=1M count=100 status=progress

echo "--- ¡TODO LISTO! Ahora lanza: sbatch run_benchmark.sh ---"