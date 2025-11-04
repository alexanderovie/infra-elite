#!/usr/bin/env bash
# Script para verificar y liberar locks orphaned de Terraform state
# Solo funciona en CI/CD donde el concurrency group previene runs simultáneos
set -euo pipefail

WORKING_DIR="${1:-terraform}"
cd "$WORKING_DIR"

echo "🔓 Verificando si hay locks activos..."

# Intentar una operación que necesite lock (plan con -lock=false no funciona para detectar)
# En su lugar, intentamos un plan mínimo que fallará si hay lock
# Pero mejor: intentamos directamente force-unlock con el ID conocido si existe
# O intentamos un plan y capturamos el error

# Estrategia: Intentar terraform plan con -refresh=false para detectar lock rápidamente
# Si falla, extraemos el Lock ID del error
PLAN_OUTPUT=$(terraform plan -refresh=false -no-color 2>&1 || true)

if echo "$PLAN_OUTPUT" | grep -q "Error acquiring the state lock"; then
  echo "⚠️  Lock detectado, extrayendo ID..."
  
  # Extraer Lock ID del error
  LOCK_ID=$(echo "$PLAN_OUTPUT" | grep -A 5 "Lock Info:" | grep "ID:" | awk '{print $2}' || echo "")
  
  if [ -n "$LOCK_ID" ]; then
    echo "🔓 Lock ID encontrado: ${LOCK_ID}"
    echo "   Intentando liberar lock orphaned (seguro porque concurrency previene runs simultáneos)..."
    
    if terraform force-unlock -force "${LOCK_ID}" 2>&1; then
      echo "✅ Lock liberado exitosamente"
    else
      echo "⚠️  No se pudo liberar el lock (puede que ya se liberó o no existe)"
    fi
  else
    echo "⚠️  No se pudo extraer el Lock ID del error"
    echo "   Output del error:"
    echo "$PLAN_OUTPUT" | head -20
  fi
else
  echo "✅ No hay locks activos"
fi
