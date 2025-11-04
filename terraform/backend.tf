# Backend remoto en Google Cloud Storage
# La configuración se inyecta dinámicamente via -backend-config en CI
terraform {
  backend "gcs" {}

  required_version = "~> 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    vercel = {
      source  = "vercel/vercel"
      version = "~> 4.0"
    }
  }
}
