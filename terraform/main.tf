# Módulos activos - Descomenta y configura según necesidades

# Ejemplo: Cloudflare Worker
# module "cloudflare_worker" {
#   source = "./modules/cloudflare_worker"
#
#   name    = "api-worker"
#   script  = file("${path.module}/../scripts/worker.js")
#   account_id = var.cloudflare_account_id
# }

# Ejemplo: DNS Record
# module "dns_record" {
#   source = "./modules/cloudflare_dns_record"
#
#   zone_id = var.cloudflare_zone_id
#   name    = "api"
#   type    = "CNAME"
#   content = "example.com"
# }

# Ejemplo: GCP Cloud Run
# module "cloud_run_service" {
#   source = "./modules/gcp_cloud_run"
#
#   name     = "api-service"
#   image    = "gcr.io/PROJECT_ID/service:latest"
#   region   = var.google_region
#   project  = var.google_project_id
# }

# === BEGIN dns_mensajeria (managed) ===
# Temporalmente restaurado para importar al estado
module "dns_mensajeria" {
  source = "./modules/cloudflare_dns_record"

  zone_id = var.cloudflare_zone_id
  name    = "mensajeria"
  type    = "CNAME"
  content = "tu-servicio-xyz-uc.a.run.app"
  proxied = true
  ttl     = 1
}
# === END dns_mensajeria (managed) ===

