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

# Opcional: Provider para Vercel
provider "vercel" {
  api_token = var.vercel_api_token != "" ? var.vercel_api_token : null
  team      = var.vercel_team_id != "" ? var.vercel_team_id : null
}
