#!/bin/bash
#SBATCH --job-name=AES_Serial_Scale
#SBATCH --output=resultado_serial_%j.out
#SBATCH --error=error_serial_%j.err
#SBATCH --nodes=1                # Solo necesitamos 1 nodo físico
#SBATCH --ntasks=1               # Solo 1 proceso (Serial puro)
#SBATCH --time=00:20:00          # Tiempo holgado

# Cargar entorno
module load gnu openmpi 2>/dev/null

echo "=========================================================="
echo " ESTUDIO DE ESCALABILIDAD - VERSIÓN SERIAL (BASELINE)"
echo " Fecha inicio: $(date)"
echo " Nodo asignado: $SLURM_JOB_NODELIST"
echo "=========================================================="

# Lista de archivos a probar (Nombres según setup.sh)
# Asegúrate de que existen. Si setup.sh generó '256M' en vez de '256MB', ajusta aquí.
DATASETS="datos.bin datos_256M.bin datos_512M.bin datos_1G.bin"
OUTPUT="salida_serial_tmp.bin"

for INPUT in $DATASETS
do
    echo ""
    echo "----------------------------------------------------------"
    
    # Comprobamos si el archivo existe antes de intentar ejecutarlo
    if [ -f "$INPUT" ]; then
        # Obtener tamaño legible para el log
        SIZE=$(ls -lh $INPUT | awk '{print $5}')
        echo "[$(date +%H:%M:%S)] >>> Procesando archivo: $INPUT ($SIZE)"
        
        # EJECUCIÓN SERIAL
        ./aes_serial $INPUT $OUTPUT
        
    else
        echo "[$(date +%H:%M:%S)] ⚠️  ALERTA: No se encuentra el archivo $INPUT"
        echo "           (Ejecuta 'bash setup.sh' para generarlo)"
    fi
done

# Limpieza
rm -f $OUTPUT

echo ""
echo "=========================================================="
echo " FIN DEL EXPERIMENTO SERIAL: $(date)"
echo "=========================================================="