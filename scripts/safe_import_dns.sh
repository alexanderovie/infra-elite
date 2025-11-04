#!/usr/bin/env bash
# Script seguro para importar recurso DNS de Cloudflare
# Maneja locks y errores de forma robusta
set -euo pipefail

MODULE_NAME="dns_mensajeria"
RECORD_NAME="mensajeria.fascinantedigital.com"

echo "🔍 Verificando si el módulo ${MODULE_NAME} está en el código..."

if ! grep -q "module \"${MODULE_NAME}\"" terraform/main.tf; then
  echo "ℹ️  Módulo ${MODULE_NAME} no está en el código, saltando import"
  exit 0
fi

echo "✅ Módulo ${MODULE_NAME} encontrado en código"

# Verificar si ya está en el estado
if terraform state list 2>/dev/null | grep -q "module.${MODULE_NAME}"; then
  echo "✅ Recurso ya está en el estado de Terraform"
  exit 0
fi

echo "📥 Importando recurso DNS desde Cloudflare..."
echo "   Record: ${RECORD_NAME}"

# Obtener Record ID desde Cloudflare API
ZONE_ID="${CLOUDFLARE_ZONE_ID:?CLOUDFLARE_ZONE_ID no configurado}"
CF_TOKEN="${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN no configurado}"

RESPONSE=$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${RECORD_NAME}&type=CNAME" \
  -H "Authorization: Bearer ${CF_TOKEN}" \
  -H "Content-Type: application/json")

# Verificar si la respuesta es exitosa
if echo "$RESPONSE" | grep -q '"success":true'; then
  RECORD_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

  if [ -z "$RECORD_ID" ]; then
    echo "⚠️  No se encontró el registro ${RECORD_NAME} en Cloudflare"
    echo "   Esto es normal si el registro no existe aún"
    exit 0
  fi

  echo "✅ Record ID encontrado: ${RECORD_ID}"
  echo "   Importando a Terraform..."

  # Intentar import con manejo de errores
  if terraform import "module.${MODULE_NAME}.cloudflare_record.this" "${ZONE_ID}/${RECORD_ID}" 2>&1; then
    echo "✅ Import exitoso"
  else
    IMPORT_ERROR=$?
    # Verificar si el error es porque ya está importado
    if terraform state list 2>/dev/null | grep -q "module.${MODULE_NAME}"; then
      echo "✅ Recurso ya está en el estado (import anterior exitoso)"
      exit 0
    else
      echo "⚠️  Import falló (código: ${IMPORT_ERROR})"
      echo "   Esto puede ser normal si:"
      echo "   - El recurso no existe en Cloudflare"
      echo "   - Hay un lock activo (se resolverá en el siguiente run)"
      echo "   - Hay un problema de permisos"
      exit 0  # No fallar el workflow por esto
    fi
  fi
else
  echo "⚠️  Error en la API de Cloudflare"
  echo "   Respuesta: ${RESPONSE}"
  exit 0  # No fallar el workflow
fi
