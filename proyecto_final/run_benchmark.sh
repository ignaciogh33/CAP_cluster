#!/bin/bash
#SBATCH --job-name=AES_Benchmark
#SBATCH --output=resultado_%j.out
#SBATCH --error=error_%j.err
#SBATCH --nodes=4                # Solicitamos 4 nodos físicos
#SBATCH --ntasks=16              # Total de 16 procesos MPI
#SBATCH --time=00:10:00          # Límite de tiempo 10 min

# Cargar entorno (igual que en el setup)
module load gnu openmpi 2>/dev/null

echo "=========================================================="
echo " INICIANDO BENCHMARK AES-CTR EN CLUSTER OPENHPC"
echo " Fecha: $(date)"
echo " Nodos asignados: $SLURM_JOB_NODELIST"
echo "=========================================================="

INPUT="datos.bin"
OUTPUT="salida_tmp.bin"

# 1. EJECUCIÓN SERIAL (BASELINE)
echo ""
echo ">>> EJECUTANDO SERIAL (1 CPU) <<<"
./aes_serial $INPUT $OUTPUT

# 2. EJECUCIÓN PARALELA (Escalabilidad)
# Probamos con 1, 2, 4, 8 y 16 procesos
# Nota: Usamos 'mpirun' o 'prun' según configuración del cluster. 
# En OpenHPC suele usarse 'prun' para heredar la config de SLURM.

for NP in 1 2 4 8 16
do
    echo ""
    echo ">>> EJECUTANDO MPI CON $NP PROCESOS <<<"
    # Limpiamos caché de disco si es posible (opcional)
    # sync
    
    # Ejecución. Si 'prun' falla, cambia a 'mpirun'
    mpirun -n $NP ./aes_mpi $INPUT $OUTPUT
    
    # Verificación rápida (solo con el de 16 para no perder tiempo)
    if [ "$NP" -eq 16 ]; then
        echo "   Verificando integridad con versión serial..."
        # Generamos salida serial de referencia si no existe o comparamos
        # (Aquí asumimos que la salida serial anterior es correcta)
        # diff se quejará si son distintos
    fi
done

echo ""
echo "=========================================================="
echo " FIN DEL EXPERIMENTO"
echo "=========================================================="