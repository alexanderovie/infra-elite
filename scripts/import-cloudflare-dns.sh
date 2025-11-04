#!/bin/bash
# Script para importar recurso DNS existente de Cloudflare a Terraform
# Uso: ./scripts/import-cloudflare-dns.sh zone_id record_name

set -euo pipefail

ZONE_ID="${1:-}"
RECORD_NAME="${2:-mensajeria}"

if [ -z "$ZONE_ID" ]; then
    echo "❌ Error: Zone ID requerido"
    echo "Uso: ./scripts/import-cloudflare-dns.sh <zone_id> [record_name]"
    exit 1
fi

# Obtener API token desde secrets o env
CF_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"
if [ -z "$CF_API_TOKEN" ]; then
    echo "❌ Error: CLOUDFLARE_API_TOKEN no configurado"
    exit 1
fi

echo "🔍 Obteniendo ID del registro DNS '${RECORD_NAME}'..."

# Obtener el record ID desde Cloudflare API
RESPONSE=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${RECORD_NAME}.fascinantedigital.com&type=CNAME" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json")

RECORD_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$RECORD_ID" ]; then
    echo "❌ Error: No se encontró el registro DNS '${RECORD_NAME}'"
    echo "Respuesta de API: $RESPONSE"
    exit 1
fi

echo "✅ Record ID encontrado: ${RECORD_ID}"
echo ""
echo "📥 Importando a Terraform..."
echo "   Comando: terraform import module.dns_mensajeria.cloudflare_record.this ${ZONE_ID}/${RECORD_ID}"

cd terraform
terraform import module.dns_mensajeria.cloudflare_record.this "${ZONE_ID}/${RECORD_ID}"

echo ""
echo "✅ Importación completada"
echo "   Ahora puedes eliminar el módulo del código y Terraform lo destruirá"

