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

# Verificar si el bucket existe
if ! gsutil ls -p "$PROJECT_ID" "gs://$BUCKET" >/dev/null 2>&1; then
  echo "🔨 Creando bucket ${BUCKET}..."
  gcloud storage buckets create "gs://$BUCKET" \
    --project="$PROJECT_ID" \
    --location="$REGION"
  echo "✅ Bucket creado"
else
  echo "✅ Bucket ya existe"
fi

# Habilitar versioning (idempotente)
echo "🔧 Habilitando versioning..."
gcloud storage buckets update "gs://$BUCKET" --versioning || echo "⚠️ Versioning ya está habilitado o no disponible"

echo "✅ Bootstrap del bucket completado"

