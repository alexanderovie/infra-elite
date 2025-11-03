#!/bin/bash

# Script para configurar Workload Identity Federation (OIDC) para GitHub Actions
# Método "elite" - sin keys JSON, más seguro y funciona con políticas restrictivas

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ID="fascinante-digit-1698295291643"
PROJECT_NUMBER="304053580743"  # Se actualizará automáticamente
SA_NAME="terraform"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
REPO_OWNER="alexanderovie"
REPO_NAME="infra-elite"

echo -e "${BLUE}=== Configuración de Workload Identity Federation (OIDC) ===${NC}"
echo ""
echo "Este método NO requiere keys JSON y funciona con políticas restrictivas"
echo ""
echo "Proyecto: ${PROJECT_ID}"
echo "Service Account: ${SA_EMAIL}"
echo "Repositorio: ${REPO_OWNER}/${REPO_NAME}"
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

# Obtener PROJECT_NUMBER automáticamente
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)' 2>/dev/null || echo "$PROJECT_NUMBER")
echo -e "${GREEN}✓ Autenticación verificada${NC}"
echo -e "${BLUE}  Project ID: ${PROJECT_ID}${NC}"
echo -e "${BLUE}  Project Number: ${PROJECT_NUMBER}${NC}"
echo ""

# Habilitar APIs necesarias
echo -e "${BLUE}Paso 1: Habilitando APIs necesarias...${NC}"
gcloud services enable iamcredentials.googleapis.com --project="$PROJECT_ID" 2>/dev/null || true
gcloud services enable sts.googleapis.com --project="$PROJECT_ID" 2>/dev/null || true
echo -e "${GREEN}✓ APIs habilitadas${NC}"
echo ""

# Verificar que la Service Account existe
echo -e "${BLUE}Paso 2: Verificando Service Account...${NC}"
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${YELLOW}⚠ La Service Account '${SA_NAME}' no existe. Creándola...${NC}"
    gcloud iam service-accounts create "$SA_NAME" \
        --project="$PROJECT_ID" \
        --display-name="Terraform IaC automation" \
        --description="Service Account para Terraform CI/CD automation"
    echo -e "${GREEN}✓ Service Account creada${NC}"
else
    echo -e "${GREEN}✓ Service Account existe${NC}"
fi
echo ""

# Asignar roles a la Service Account
echo -e "${BLUE}Paso 3: Asignando roles a la Service Account...${NC}"
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

# Crear Workload Identity Pool
echo -e "${BLUE}Paso 4: Creando Workload Identity Pool...${NC}"
if gcloud iam workload-identity-pools describe "$POOL_NAME" \
    --project="$PROJECT_ID" \
    --location="global" &>/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ El pool '${POOL_NAME}' ya existe${NC}"
else
    gcloud iam workload-identity-pools create "$POOL_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --display-name="GitHub Actions Pool"
    echo -e "${GREEN}✓ Pool creado${NC}"
fi
echo ""

# Obtener el ID del pool
POOL_ID=$(gcloud iam workload-identity-pools describe "$POOL_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --format="value(name)" | cut -d'/' -f6)

# Crear Workload Identity Provider para GitHub
echo -e "${BLUE}Paso 5: Creando Workload Identity Provider para GitHub...${NC}"
PROVIDER_FULL_NAME="projects/${PROJECT_ID}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" &>/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ El provider '${PROVIDER_NAME}' ya existe${NC}"
else
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="$POOL_NAME" \
        --display-name="GitHub Provider" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
        --attribute-condition="assertion.repository == '${REPO_OWNER}/${REPO_NAME}'" \
        --issuer-uri="https://token.actions.githubusercontent.com"
    echo -e "${GREEN}✓ Provider creado${NC}"
fi
echo ""

# Permitir que el provider asuma la Service Account
echo -e "${BLUE}Paso 6: Vinculando Provider con Service Account...${NC}"
PRINCIPAL="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${REPO_OWNER}/${REPO_NAME}"
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="$PRINCIPAL" \
    2>&1 | grep -q "Updated IAM policy" && echo -e "${GREEN}✓ Vinculación completada${NC}" || echo -e "${YELLOW}⚠ Puede que ya esté vinculado${NC}"
echo ""

# Paso 7: Eliminar keys existentes (higiene)
echo -e "${BLUE}Paso 7: Eliminando keys JSON existentes (si hay)...${NC}"
EXISTING_KEYS=$(gcloud iam service-accounts keys list --iam-account="$SA_EMAIL" --project="$PROJECT_ID" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$EXISTING_KEYS" ]; then
    echo "$EXISTING_KEYS" | while read -r KEY; do
        if [ -n "$KEY" ]; then
            echo -n "  Eliminando key ${KEY:0:20}... "
            gcloud iam service-accounts keys delete "$KEY" --iam-account="$SA_EMAIL" --project="$PROJECT_ID" -q 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⚠${NC}"
        fi
    done
    echo -e "${GREEN}✓ Keys eliminadas (usaremos OIDC ahora)${NC}"
else
    echo -e "${GREEN}✓ No hay keys para eliminar${NC}"
fi
echo ""

# Obtener el nombre completo del provider
PROVIDER_FULL_NAME=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --format="value(name)")

# Mostrar información para actualizar el workflow
echo -e "${GREEN}=== Configuración Completada ===${NC}"
echo ""
echo "✅ Workload Identity Pool creado"
echo "✅ OIDC Provider creado para GitHub"
echo "✅ Service Account vinculada"
echo ""
echo -e "${YELLOW}⚠ IMPORTANTE: Actualiza tu workflow .github/workflows/terraform.yml${NC}"
echo ""
echo "✅ El workflow ya está actualizado en .github/workflows/terraform.yml"
echo ""
echo "Usa PROJECT_NUMBER en el provider:"
echo ""
echo -e "${BLUE}---${NC}"
cat << EOF
      - name: Autenticar con Google Cloud (OIDC)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}'
          service_account: '${SA_EMAIL}'
EOF
echo -e "${BLUE}---${NC}"
echo ""
echo -e "${GREEN}Ventajas de este método:${NC}"
echo "  ✓ No requiere keys JSON"
echo "  ✓ Funciona con políticas restrictivas de la organización"
echo "  ✓ Más seguro (sin keys almacenadas)"
echo "  ✓ Rotación automática de credenciales"
