#!/bin/bash

# ================================
# Script para probar DNS CNAME en Cloudflare
# Crea mensajeria.fascinantedigital.com -> target.example.com
# ================================

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de Prueba DNS: Mensajería ===${NC}"
echo ""

# ================================
# 0) Definir variables (AJUSTA)
# ================================

# ZONE_ID_CF - Obtener de Cloudflare Dashboard o usar el secret de GitHub
# Para obtenerlo: gh secret list | grep ZONE_ID
ZONE_ID_CF="${ZONE_ID_CF:-}"
if [ -z "$ZONE_ID_CF" ]; then
    echo -e "${YELLOW}⚠ ZONE_ID_CF no definido.${NC}"
    echo "   Obtén el Zone ID de: https://dash.cloudflare.com"
    echo "   O usa: gh secret list | grep ZONE_ID"
    read -p "   Ingresa el Zone ID de Cloudflare: " ZONE_ID_CF
fi

# Target del CNAME (ajusta según tu servicio real)
CNAME_TARGET="${CNAME_TARGET:-target.example.com}"
echo -e "${YELLOW}Target CNAME: ${CNAME_TARGET}${NC}"
echo "   Esto creará: mensajeria.fascinantedigital.com -> ${CNAME_TARGET}"
read -p "   ¿Continuar? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${RED}Cancelado${NC}"
    exit 0
fi

# ================================
# 1) Verificar que estamos en el repo correcto
# ================================

if [ ! -f "terraform/main.tf" ]; then
    echo -e "${RED}Error: No estás en el directorio del proyecto${NC}"
    echo "   Ejecuta desde: /home/alexander/proyectos/infra-elite"
    exit 1
fi

# ================================
# 2) Crear rama para el cambio
# ================================

BRANCH="feat/dns-mensajeria"
if git branch --show-current 2>/dev/null | grep -q "$BRANCH"; then
    echo -e "${YELLOW}Ya estás en la rama $BRANCH${NC}"
else
    echo -e "${GREEN}Creando rama: $BRANCH${NC}"
    git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
fi

# ================================
# 3) Agregar módulo DNS a main.tf
# ================================

echo -e "${GREEN}Agregando módulo DNS a terraform/main.tf${NC}"

# Verificar si ya existe el módulo mensajeria
if grep -q "module \"mensajeria_dns\"" terraform/main.tf; then
    echo -e "${YELLOW}⚠ El módulo mensajeria_dns ya existe en main.tf${NC}"
    read -p "   ¿Reemplazarlo? (y/n): " replace
    if [ "$replace" = "y" ] || [ "$replace" = "Y" ]; then
        # Eliminar el módulo existente (líneas entre el comentario y el siguiente módulo o final)
        sed -i '/# --- Mensajería subdomain/,/^}$/d' terraform/main.tf
    else
        echo -e "${RED}Cancelado${NC}"
        exit 0
    fi
fi

# Agregar el módulo al final del archivo
cat >> terraform/main.tf <<EOF

# --- Mensajería subdomain (test DNS) ---
module "mensajeria_dns" {
  source = "./modules/cloudflare_dns_record"

  zone_id = var.cloudflare_zone_id
  name    = "mensajeria"
  type    = "CNAME"
  content = "${CNAME_TARGET}"
  proxied = true  # true = pasa por Cloudflare (WAF/Cache/TLS)
  ttl     = 1     # 1 = Auto
  comment = "Test DNS para mensajería - creado por script"
}
EOF

echo -e "${GREEN}✓ Módulo agregado${NC}"

# ================================
# 4) Commit y Push
# ================================

echo ""
echo -e "${GREEN}Preparando commit...${NC}"
git add terraform/main.tf

if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠ No hay cambios para commitear${NC}"
else
    git commit -m "feat(dns): add mensajeria CNAME -> ${CNAME_TARGET}

- Agrega mensajeria.fascinantedigital.com apuntando a ${CNAME_TARGET}
- Usa módulo cloudflare_dns_record
- Proxy de Cloudflare activado"

    echo -e "${GREEN}✓ Commit creado${NC}"
    echo ""
    echo -e "${GREEN}Haciendo push a origin/${BRANCH}...${NC}"
    git push -u origin "$BRANCH" || {
        echo -e "${RED}Error en push. ¿Quieres intentar de nuevo?${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Push completado${NC}"
fi

# ================================
# 5) Resumen y próximos pasos
# ================================

echo ""
echo -e "${GREEN}=== ✅ Completado ===${NC}"
echo ""
echo "📋 Próximos pasos:"
echo ""
echo "1. Abre el Pull Request en GitHub:"
echo "   https://github.com/alexanderovie/infra-elite/compare/main...${BRANCH}"
echo ""
echo "2. El workflow de GitHub Actions ejecutará 'terraform plan'"
echo "   y mostrará que se creará 1 recurso DNS (CNAME)"
echo ""
echo "3. Si el plan se ve correcto, haz Merge a 'main'"
echo "   → Esto disparará 'terraform apply' automáticamente"
echo ""
echo "4. Después del apply (espera 1-5 min para propagación DNS):"
echo "   dig +short mensajeria.fascinantedigital.com CNAME"
echo "   nslookup mensajeria.fascinantedigital.com"
echo "   curl -I https://mensajeria.fascinantedigital.com"
echo ""
echo "5. Para rollback (si necesitas revertir):"
echo "   git checkout -b fix/remove-mensajeria"
echo "   # Edita terraform/main.tf y elimina el módulo mensajeria_dns"
echo "   git add terraform/main.tf"
echo "   git commit -m 'revert(dns): remove mensajeria CNAME'"
echo "   git push -u origin fix/remove-mensajeria"
echo ""
