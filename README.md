# Infra Elite - Infraestructura como Código

Infraestructura gestionada con Terraform para servicios de Fascinante Digital.

## Estructura

```
infra-elite/
├── terraform/           # Configuración de Terraform
│   ├── modules/         # Módulos reutilizables
│   └── *.tf            # Archivos principales
├── scripts/            # Scripts de automatización
└── .github/workflows/  # CI/CD con GitHub Actions
```

## Módulos Disponibles

- **cloudflare_worker**: Despliegue de Workers en Cloudflare
- **cloudflare_dns_record**: Gestión de registros DNS
- **gcp_cloud_run**: Servicios en Google Cloud Run
- **supabase_init** (opcional): Configuración de Supabase
- **stripe_products** (opcional): Gestión de productos Stripe

## Requisitos Previos

- Terraform >= 1.5.0
- Google Cloud SDK (para GCP)
- Cloudflare API Token
- Acceso a servicios configurados

## Configuración

1. Copia `.env.example` a `.env` y completa las variables:

```bash
cp .env.example .env
```

2. Configura las credenciales según tu entorno

## Uso

### CLI Personalizado

Usa el script `scripts/elite` para gestionar la infraestructura:

```bash
# Ver ayuda
./scripts/elite --help

# Planificar cambios (sin entorno específico)
./scripts/elite plan

# Planificar cambios para desarrollo
./scripts/elite plan -e dev

# Aplicar cambios para staging
./scripts/elite apply -e stage

# Aplicar cambios para producción (sin confirmación)
./scripts/elite apply -e prod -y

# Destruir recursos de desarrollo
./scripts/elite destroy -e dev
```

### Archivos de Entorno

Los archivos `.tfvars` en `terraform/envs/` permiten configurar variables específicas por entorno:

- `dev.tfvars` - Variables para desarrollo
- `stage.tfvars` - Variables para staging
- `prod.tfvars` - Variables para producción

Usa la opción `-e` o `--env` para especificar el entorno al ejecutar comandos.

### Terraform Directo

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## CI/CD

El workflow de GitHub Actions (`/.github/workflows/terraform.yml`) ejecuta automáticamente:
- `terraform init`
- `terraform plan`
- `terraform apply` (en merge a main)

## Backend

El estado de Terraform se almacena en Google Cloud Storage (GCS) configurado en `terraform/backend.tf`.

## Seguridad

⚠️ **Importante**: Nunca commitees archivos `.env` o credenciales. Usa secretos de GitHub Actions para CI/CD.
