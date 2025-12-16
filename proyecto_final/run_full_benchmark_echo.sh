#!/bin/bash
#SBATCH --job-name=AES_1GB_Bench
#SBATCH --output=resultado_%j.out
#SBATCH --error=error_%j.err
#SBATCH --nodes=4                
#SBATCH --ntasks=16              
#SBATCH --time=00:30:00          # Subido a 30 min por si acaso (1GB tarda más)

# Cargar entorno
module load gnu openmpi 2>/dev/null

echo "=========================================================="
echo " ESTUDIO AVANZADO AES-CTR (DATASET 512 MB)"
echo " Fecha inicio: $(date)"
echo " Nodos: $SLURM_JOB_NODELIST"
echo "=========================================================="

# --- CONFIGURACIÓN ---
INPUT="datos.bin"
SERIAL_OUT="salida_serial.bin"
MPI_OUT="salida_mpi.bin"

# --- 1. BASELINE SERIAL ---
echo ""
echo "[$(date +%H:%M:%S)] >>> INICIANDO SERIAL (1 CPU)... Por favor espere."
./aes_serial $INPUT $SERIAL_OUT
echo "[$(date +%H:%M:%S)] >>> Serial TERMINADO."

# --- 2. BUCLE DE PRUEBAS PARALELAS ---
PROCESS_COUNTS="1 2 4 6 8 10 14 16"

for NP in $PROCESS_COUNTS
do
    echo "----------------------------------------------------------"
    echo "[$(date +%H:%M:%S)] PRUEBAS CON $NP PROCESOS"
    echo "----------------------------------------------------------"

    # --- ESCENARIO A: CENTRALIZADO ---
    echo "   [A] Ejecutando CENTRALIZADO (Compact)..."
    mpirun --map-by core -n $NP ./aes_mpi $INPUT $MPI_OUT
    
    # --- ESCENARIO B: DISTRIBUIDO (Solo si NP > 1) ---
    if [ "$NP" -gt 1 ]; then
        echo "   [B] Ejecutando DISTRIBUIDO (Spread)..."
        mpirun --map-by node -n $NP ./aes_mpi $INPUT $MPI_OUT
    fi

    # Verificación de integridad (Solo en la última vuelta para ahorrar disco)
    if [ "$NP" -eq 16 ]; then
        echo "" 
        echo "[$(date +%H:%M:%S)] [*] Verificando integridad binaria..."
        diff -q $SERIAL_OUT $MPI_OUT && echo "       -> OK: Archivo idéntico." || echo "       -> ERROR: Fichero corrupto."
    fi
done

# Limpieza final (Opcional: borra los archivos generados de 1GB para liberar espacio)
rm -f $SERIAL_OUT $MPI_OUT

echo ""
echo "=========================================================="
echo " FIN DEL EXPERIMENTO: $(date)"
echo "=========================================================="