provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "google" {
  project = var.google_project_id
  region  = var.google_region
}

# Opcional: Provider para Supabase
# provider "supabase" {
#   access_token = var.supabase_access_token
# }
