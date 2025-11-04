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

# === BEGIN storage_bucket_test (managed) ===
# Bucket de prueba para validar el módulo GCP Storage
module "storage_bucket_test" {
  source = "./modules/gcp_storage_bucket"

  project_id  = var.google_project_id
  bucket_name = "test-bucket-${random_id.bucket_suffix.hex}"
  location    = "US"

  enable_versioning              = true
  uniform_bucket_level_access    = true
  public_access_prevention       = "enforced"

  labels = {
    environment = "test"
    purpose     = "validation"
    managed_by  = "terraform"
  }
}

# Random ID para asegurar nombre único del bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
# === END storage_bucket_test (managed) ===

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
