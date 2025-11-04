# Backend remoto en Google Cloud Storage
terraform {
  backend "gcs" {
    bucket = "terraform-state-fascinante-digit-1698295291643"
    prefix = "infra-elite/terraform.tfstate"
  }
}
