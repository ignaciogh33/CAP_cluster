#!/bin/bash
#SBATCH --job-name=AES_Full_Benchmark
#SBATCH --output=resultado_%j.out
#SBATCH --error=error_%j.err
#SBATCH --nodes=4                # Mantenemos 4 nodos para tener espacio de maniobra
#SBATCH --ntasks=16              # Reservamos 16 slots en total
#SBATCH --time=00:20:00          # Aumentamos tiempo por seguridad

# Cargar entorno
module load gnu openmpi 2>/dev/null

echo "=========================================================="
echo " ESTUDIO AVANZADO DE RENDIMIENTO AES-CTR"
echo " Fecha: $(date)"
echo " Nodos asignados: $SLURM_JOB_NODELIST"
echo "=========================================================="

INPUT="datos.bin"
OUTPUT="salida_tmp.bin"

# --- 1. BASELINE SERIAL ---
echo ""
echo ">>> EJECUTANDO SERIAL (1 CPU) <<<"
# Medimos tiempo del serial una sola vez como referencia base
./aes_serial $INPUT $OUTPUT

# --- 2. BUCLE DE PRUEBAS PARALELAS ---
# Lista ampliada de procesos
PROCESS_COUNTS="1 2 4 6 8 10 14 16"

for NP in $PROCESS_COUNTS
do
    echo "----------------------------------------------------------"
    echo " PRUEBAS CON $NP PROCESOS"
    echo "----------------------------------------------------------"

    # --- ESCENARIO A: CENTRALIZADO (Compact) ---
    # --map-by core: Llena los slots de un nodo antes de saltar al siguiente.
    # Ideal para aprovechar la caché compartida y evitar red si caben en un nodo.
    echo "   [A] Modo CENTRALIZADO (Compact/Fill):"
    mpirun --map-by core -n $NP ./aes_mpi $INPUT $OUTPUT
    
    # --- ESCENARIO B: DISTRIBUIDO (Spread) ---
    # --map-by node: Asigna procesos en Round-Robin por los nodos.
    # Si tenemos 4 nodos y NP=4, pondrá 1 proceso en cada nodo.
    # Fuerza el uso de la red al máximo.
    # Solo ejecutamos esto si tiene sentido (NP > 1)
    if [ "$NP" -gt 1 ]; then
        echo "   [B] Modo DISTRIBUIDO (Spread/Round-Robin):"
        mpirun --map-by node -n $NP ./aes_mpi $INPUT $OUTPUT
    fi

    # Verificación de integridad (solo en la carga más alta para ahorrar tiempo)
    if [ "$NP" -eq 16 ]; then
        echo "" 
        echo "   [*] Verificando integridad final..."
        # Usamos diff silencioso, si sale bien no dice nada, si falla avisa
        diff -q $OUTPUT salida_tmp.bin && echo "       -> OK: Archivo idéntico al serial." || echo "       -> ERROR: Fichero corrupto."
    fi
done

echo ""
echo "=========================================================="
echo " FIN DEL EXPERIMENTO COMPLETO"
echo "=========================================================="