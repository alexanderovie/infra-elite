#!/bin/bash

# Script para crear Service Account de Terraform en GCP y configurar secreto en GitHub
# Método rápido usando gcloud CLI

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ID="fascinante-digit-1698295291643"
SA_NAME="terraform"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="./gcp-terraform-key.json"

echo -e "${BLUE}=== Configuración de Service Account para Terraform ===${NC}"
echo ""
echo "Proyecto: ${PROJECT_ID}"
echo "Service Account: ${SA_NAME}"
echo "Email: ${SA_EMAIL}"
echo ""

# Verificar que gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI no está instalado${NC}"
    exit 1
fi

# Verificar autenticación
echo -e "${YELLOW}Verificando autenticación de gcloud...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠ No hay cuentas activas. Ejecutando login...${NC}"
    gcloud auth login
fi

# Verificar proyecto
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo -e "${YELLOW}Configurando proyecto a ${PROJECT_ID}...${NC}"
    gcloud config set project "$PROJECT_ID"
fi

echo -e "${GREEN}✓ Autenticación verificada${NC}"
echo ""

# Paso 1: Crear Service Account
echo -e "${BLUE}Paso 1: Creando Service Account...${NC}"
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${YELLOW}⚠ La Service Account '${SA_NAME}' ya existe${NC}"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --project="$PROJECT_ID" \
        --display-name="Terraform IaC automation" \
        --description="Service Account para Terraform CI/CD automation"
    echo -e "${GREEN}✓ Service Account creada${NC}"
fi
echo ""

# Paso 2: Asignar roles
echo -e "${BLUE}Paso 2: Asignando roles necesarios...${NC}"
ROLES=(
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/pubsub.admin"
    "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
    echo -n "  Asignando ${ROLE}... "
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="$ROLE" \
        --condition=None \
        --quiet &>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⚠ (puede que ya esté asignado)${NC}"
done
echo ""

# Paso 3: Crear key JSON
echo -e "${BLUE}Paso 3: Generando key JSON...${NC}"
if [ -f "$KEY_FILE" ]; then
    echo -e "${YELLOW}⚠ El archivo ${KEY_FILE} ya existe${NC}"
    read -p "¿Sobrescribir? (y/n): " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
    fi
fi

gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL" \
    --project="$PROJECT_ID"

echo -e "${GREEN}✓ Key JSON creada en: ${KEY_FILE}${NC}"
echo ""

# Paso 4: Configurar como secreto en GitHub
echo -e "${BLUE}Paso 4: Configurando como secreto en GitHub...${NC}"
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) no está instalado${NC}"
    echo "Instálalo desde: https://cli.github.com/"
    echo ""
    echo -e "${YELLOW}Puedes configurarlo manualmente después con:${NC}"
    echo "gh secret set GOOGLE_CREDENTIALS -b\"\$(cat ${KEY_FILE})\""
    exit 1
fi

if ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}⚠ GitHub CLI no está autenticado${NC}"
    gh auth login
fi

echo -e "${BLUE}Subiendo secreto GOOGLE_CREDENTIALS...${NC}"
gh secret set GOOGLE_CREDENTIALS -b"$(cat "$KEY_FILE")"
echo -e "${GREEN}✓ Secreto GOOGLE_CREDENTIALS configurado en GitHub${NC}"
echo ""

# Paso 5: Limpiar (opcional)
echo -e "${YELLOW}¿Deseas eliminar el archivo local ${KEY_FILE} por seguridad? (recomendado)${NC}"
read -p "(y/n): " delete_file
if [ "$delete_file" = "y" ] || [ "$delete_file" = "Y" ]; then
    rm -f "$KEY_FILE"
    echo -e "${GREEN}✓ Archivo local eliminado${NC}"
else
    echo -e "${YELLOW}⚠ Archivo local conservado en: ${KEY_FILE}${NC}"
    echo -e "${RED}IMPORTANTE: Asegúrate de no commitear este archivo!${NC}"
fi
echo ""

# Resumen
echo -e "${GREEN}=== Configuración Completada ===${NC}"
echo ""
echo "✅ Service Account creada: ${SA_EMAIL}"
echo "✅ Roles asignados:"
for ROLE in "${ROLES[@]}"; do
    echo "   - ${ROLE}"
done
echo "✅ Secreto GOOGLE_CREDENTIALS configurado en GitHub"
echo ""
echo -e "${BLUE}Verifica los secretos con:${NC}"
echo "gh secret list"
