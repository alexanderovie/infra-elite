# Cloudflare
variable "cloudflare_api_token" {
  description = "API Token de Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Account ID de Cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID del dominio en Cloudflare"
  type        = string
  default     = ""
}

# GCP
variable "google_project_id" {
  description = "ID del proyecto en Google Cloud"
  type        = string
}

variable "google_region" {
  description = "Región de Google Cloud"
  type        = string
  default     = "us-central1"
}

# Supabase (opcional)
variable "supabase_url" {
  description = "URL del proyecto Supabase"
  type        = string
  default     = ""
}

variable "supabase_anon_key" {
  description = "Anon Key de Supabase"
  type        = string
  default     = ""
  sensitive   = true
}

# Stripe (opcional)
variable "stripe_secret_key" {
  description = "Secret Key de Stripe"
  type        = string
  default     = ""
  sensitive   = true
}

# Vercel (opcional)
variable "vercel_api_token" {
  description = "API Token de Vercel"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vercel_team_id" {
  description = "Team ID de Vercel (opcional, para teams)"
  type        = string
  default     = ""
}
