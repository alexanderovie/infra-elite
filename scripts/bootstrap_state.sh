#!/usr/bin/env bash
# Script idempotente para crear y configurar el bucket GCS para Terraform state
set -euo pipefail

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-${GCLOUD_PROJECT:-}}"
BUCKET="${TF_STATE_BUCKET:?TF_STATE_BUCKET no está configurado}"
REGION="${TF_STATE_REGION:-us}"

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: GOOGLE_CLOUD_PROJECT o GCLOUD_PROJECT debe estar configurado"
  exit 1
fi

echo "📦 Configurando bucket GCS para Terraform state..."
echo "   Proyecto: ${PROJECT_ID}"
echo "   Bucket: ${BUCKET}"
echo "   Región: ${REGION}"

# Verificar si el bucket existe y es accesible
if gsutil ls -p "$PROJECT_ID" "gs://$BUCKET" >/dev/null 2>&1; then
  echo "✅ Bucket ya existe y es accesible"
else
  echo "🔨 Intentando crear bucket ${BUCKET}..."
  # Intentar crear el bucket
  if gcloud storage buckets create "gs://$BUCKET" \
    --project="$PROJECT_ID" \
    --location="$REGION" 2>&1; then
    echo "✅ Bucket creado exitosamente"
  else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 1 ]; then
      # Capturar el mensaje de error completo
      ERROR_OUTPUT=$(gcloud storage buckets create "gs://$BUCKET" \
        --project="$PROJECT_ID" \
        --location="$REGION" 2>&1 || true)
      
      # Verificar si el error es porque el bucket ya existe (y lo creamos nosotros)
      if echo "$ERROR_OUTPUT" | grep -q "409.*you already own it\|already exists"; then
        echo "✅ El bucket ya existe y tú lo creaste"
        echo "   Verificando acceso..."
        # Intentar verificar acceso (sin el flag -p para usar credenciales actuales)
        if gsutil ls "gs://$BUCKET" >/dev/null 2>&1; then
          echo "✅ Tienes acceso al bucket"
        else
          echo "⚠️  No se pudo verificar acceso, pero el bucket existe (continuando...)"
        fi
      elif echo "$ERROR_OUTPUT" | grep -q "409.*not available"; then
        echo "⚠️  El nombre del bucket ya está ocupado por otro usuario"
        echo "   Intentando usar el bucket existente..."
        if gsutil ls "gs://$BUCKET" >/dev/null 2>&1; then
          echo "✅ Tienes acceso al bucket existente"
        else
          echo "❌ No tienes acceso al bucket. Por favor, cambia TF_STATE_BUCKET a un nombre único"
          exit 1
        fi
      else
        echo "❌ Error creando bucket: $ERROR_OUTPUT"
        exit 1
      fi
    else
      echo "❌ Error inesperado creando bucket"
      exit 1
    fi
  fi
fi

# Habilitar versioning (idempotente)
echo "🔧 Habilitando versioning..."
gcloud storage buckets update "gs://$BUCKET" --versioning || echo "⚠️ Versioning ya está habilitado o no disponible"

echo "✅ Bootstrap del bucket completado"
