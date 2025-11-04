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

# === BEGIN worker_test (managed) ===
# Worker de prueba para validar el pipeline
module "worker_test" {
  source = "./modules/cloudflare_worker"

  account_id = var.cloudflare_account_id
  name       = "test-worker"
  script     = file("${path.module}/../workers/test-worker/index.js")
  
  # Sin route (worker standalone, se invoca via API o binding)
  zone_id       = var.cloudflare_zone_id
  route_pattern = ""
  
  plain_text_bindings = []
  secret_text_bindings = []
}
# === END worker_test (managed) ===

