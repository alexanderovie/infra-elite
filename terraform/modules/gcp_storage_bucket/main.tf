# Módulo para crear Google Cloud Storage Bucket
# Validado siguiendo método "elite": docs oficiales + schema + validación local

resource "google_storage_bucket" "this" {
  name     = var.bucket_name
  location = var.location
  project  = var.project_id

  # Destrucción forzada (opcional, útil para desarrollo)
  force_destroy = var.force_destroy

  # Versioning (útil para backups y recuperación)
  dynamic "versioning" {
    for_each = var.enable_versioning ? [1] : []
    content {
      enabled = true
    }
  }

  # Uniform bucket-level access (recomendado por Google)
  uniform_bucket_level_access = var.uniform_bucket_level_access

  # Prevenir acceso público (seguridad por defecto)
  public_access_prevention = var.public_access_prevention

  # Labels para organización y cost tracking
  labels = merge(
    {
      managed_by = "terraform"
      module     = "gcp_storage_bucket"
    },
    var.labels
  )

  # Lifecycle rules (opcional)
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state           = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions   = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }

  # CORS configuration (opcional)
  dynamic "cors" {
    for_each = var.cors_config
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = lookup(cors.value, "response_header", [])
      max_age_seconds = lookup(cors.value, "max_age_seconds", null)
    }
  }
}
