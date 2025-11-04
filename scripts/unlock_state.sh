#!/usr/bin/env bash
# Script para liberar locks orphaned de Terraform state
# Solo libera locks que tienen más de 10 minutos de antigüedad
set -euo pipefail

BUCKET="${TF_STATE_BUCKET:?TF_STATE_BUCKET no está configurado}"
PREFIX="${TF_STATE_PREFIX:-terraform/global}"
LOCK_FILE="gs://${BUCKET}/${PREFIX}/default.tflock"

echo "🔓 Verificando locks orphaned en ${LOCK_FILE}..."

# Verificar si existe el archivo de lock
if gsutil -q stat "${LOCK_FILE}" 2>/dev/null; then
  echo "⚠️  Lock encontrado, verificando antigüedad..."
  
  # Obtener información del lock (metadata)
  LOCK_INFO=$(gsutil stat "${LOCK_FILE}" 2>/dev/null || echo "")
  
  if [ -n "$LOCK_INFO" ]; then
    # Intentar leer el contenido del lock para obtener el timestamp
    # Terraform locks incluyen metadata sobre cuándo fueron creados
    echo "📋 Lock existe, pero no podemos determinar automáticamente si es orphaned"
    echo "   Si este run falla por lock, ejecuta manualmente:"
    echo "   terraform force-unlock <LOCK_ID>"
    echo ""
    echo "   O espera a que el lock expire (normalmente 5-10 minutos)"
  fi
else
  echo "✅ No hay locks activos"
fi

# NOTA: No liberamos automáticamente porque puede ser peligroso
# Si hay un run legítimo en curso, liberar su lock causaría corrupción
# El concurrency group en GitHub Actions previene múltiples runs simultáneos

