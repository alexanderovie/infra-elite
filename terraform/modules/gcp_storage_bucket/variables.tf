# Variables para el módulo de GCP Storage Bucket

variable "project_id" {
  description = "ID del proyecto de Google Cloud"
  type        = string
}

variable "bucket_name" {
  description = "Nombre del bucket (debe ser único globalmente)"
  type        = string
}

variable "location" {
  description = "Ubicación del bucket (region o multi-region como 'US', 'EU', 'us-central1')"
  type        = string
  default     = "US"
}

variable "force_destroy" {
  description = "Si es true, permite eliminar el bucket aunque contenga objetos"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Habilitar versioning en el bucket"
  type        = bool
  default     = true
}

variable "uniform_bucket_level_access" {
  description = "Habilitar uniform bucket-level access (recomendado)"
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Prevenir acceso público: 'inherited' o 'enforced'"
  type        = string
  default     = "enforced"
  validation {
    condition     = contains(["inherited", "enforced"], var.public_access_prevention)
    error_message = "public_access_prevention debe ser 'inherited' o 'enforced'"
  }
}

variable "labels" {
  description = "Mapa de labels para el bucket"
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "Lista de reglas de lifecycle para el bucket"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                 = optional(number)
      created_before      = optional(string)
      with_state          = optional(string)
      matches_storage_class = optional(list(string))
      num_newer_versions  = optional(number)
    })
  }))
  default = []
}

variable "cors_config" {
  description = "Configuración CORS para el bucket"
  type = list(object({
    origin          = list(string)
    method          = list(string)
    response_header = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []
}
