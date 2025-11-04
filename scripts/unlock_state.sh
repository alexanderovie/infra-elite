#!/usr/bin/env bash
# Script para verificar y liberar locks orphaned de Terraform state
# Solo funciona en CI/CD donde el concurrency group previene runs simultáneos
set -euo pipefail

LOCK_ID="${1:-}"
WORKING_DIR="${2:-terraform}"

if [ -z "$LOCK_ID" ]; then
  echo "🔓 Verificando si hay locks activos..."
  
  # Intentar listar el estado - si falla por lock, capturamos el ID
  cd "$WORKING_DIR"
  if terraform state list >/dev/null 2>&1; then
    echo "✅ No hay locks activos"
    exit 0
  else
    # El error contiene el Lock ID
    LOCK_ERROR=$(terraform state list 2>&1 || true)
    if echo "$LOCK_ERROR" | grep -q "Lock Info:"; then
      LOCK_ID=$(echo "$LOCK_ERROR" | grep -A 1 "Lock Info:" | grep "ID:" | awk '{print $2}')
      if [ -n "$LOCK_ID" ]; then
        echo "⚠️  Lock encontrado: ${LOCK_ID}"
        echo "   Intentando liberar lock orphaned..."
        terraform force-unlock -force "${LOCK_ID}" || echo "⚠️  No se pudo liberar el lock (puede ser legítimo)"
      fi
    fi
  fi
else
  echo "🔓 Liberando lock específico: ${LOCK_ID}"
  cd "$WORKING_DIR"
  terraform force-unlock -force "${LOCK_ID}" || {
    echo "⚠️  No se pudo liberar el lock ${LOCK_ID}"
    exit 0  # No fallar el workflow
  }
  echo "✅ Lock liberado exitosamente"
fi
