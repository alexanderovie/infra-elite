#!/bin/bash

# Script para configurar secretos de GitHub Actions
# Usa GitHub CLI (gh) para configurar secretos de forma segura

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Configuración de Secretos de GitHub Actions ===${NC}"
echo ""

# Verificar que gh CLI está instalado y autenticado
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) no está instalado${NC}"
    echo "Instálalo desde: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠ GitHub CLI no está autenticado${NC}"
    echo "Ejecutando: gh auth login"
    gh auth login
fi

echo -e "${GREEN}✓ GitHub CLI autenticado${NC}"
echo ""

# Listar secretos actuales
echo -e "${BLUE}Secretos actualmente configurados:${NC}"
gh secret list
echo ""

# Función para configurar un secreto interactivamente
set_secret_interactive() {
    local secret_name=$1
    local description=$2
    local is_file=${3:-false}

    echo -e "${YELLOW}Configurando: ${secret_name}${NC}"
    echo "  ${description}"

    if [ "$is_file" = true ]; then
        read -p "  Ruta al archivo JSON (o presiona Enter para omitir): " file_path
        if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            echo -e "${BLUE}  Configurando desde archivo...${NC}"
            gh secret set "$secret_name" -b"$(cat "$file_path")"
            echo -e "${GREEN}  ✓ ${secret_name} configurado${NC}"
        else
            echo -e "${YELLOW}  ⚠ Omitido${NC}"
        fi
    else
        read -sp "  Valor del secreto (no se mostrará en pantalla): " secret_value
        echo ""
        if [ -n "$secret_value" ]; then
            echo "$secret_value" | gh secret set "$secret_name"
            echo -e "${GREEN}  ✓ ${secret_name} configurado${NC}"
        else
            echo -e "${YELLOW}  ⚠ Omitido (valor vacío)${NC}"
        fi
    fi
    echo ""
}

# Secretos requeridos para el workflow actual
echo -e "${BLUE}=== Secretos Requeridos para CI/CD ===${NC}"
echo ""

set_secret_interactive "CLOUDFLARE_API_TOKEN" "API Token de Cloudflare (obtener de https://dash.cloudflare.com/profile/api-tokens)" false
set_secret_interactive "CLOUDFLARE_ACCOUNT_ID" "Account ID de Cloudflare (encontrar en el dashboard de Cloudflare)" false
set_secret_interactive "GOOGLE_CREDENTIALS" "Service Account Key de GCP (archivo JSON)" true
set_secret_interactive "GOOGLE_PROJECT_ID" "ID del proyecto en Google Cloud Platform" false

# Secretos opcionales
echo -e "${BLUE}=== Secretos Opcionales ===${NC}"
echo ""

read -p "¿Configurar secretos opcionales? (y/n): " setup_optional
if [ "$setup_optional" = "y" ] || [ "$setup_optional" = "Y" ]; then
    set_secret_interactive "CLOUDFLARE_ZONE_ID" "Zone ID del dominio en Cloudflare (opcional)" false
    set_secret_interactive "STRIPE_API_KEY" "API Key de Stripe (opcional)" false
    set_secret_interactive "SUPABASE_ACCESS_TOKEN" "Access Token de Supabase (opcional)" false
    set_secret_interactive "SUPABASE_PROJECT_REF" "Project Reference de Supabase (opcional)" false
fi

echo ""
echo -e "${GREEN}=== Configuración Completada ===${NC}"
echo ""
echo "Secretos configurados:"
gh secret list
echo ""
echo -e "${BLUE}Nota:${NC} Los secretos están encriptados y solo son visibles en GitHub Actions durante la ejecución de los workflows."
