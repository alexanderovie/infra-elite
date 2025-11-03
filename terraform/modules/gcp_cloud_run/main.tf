resource "google_cloud_run_service" "this" {
  name     = var.name
  location = var.region
  project  = var.project

  template {
    spec {
      containers {
        image = var.image

        ports {
          container_port = var.container_port
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }

        dynamic "env" {
          for_each = var.environment_variables
          content {
            name  = env.key
            value = env.value
          }
        }

        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }
      }

      container_concurrency = var.concurrency
      timeout_seconds      = var.timeout
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
        "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# IAM: Permitir acceso público o restringido
resource "google_cloud_run_service_iam_member" "public" {
  count = var.allow_unauthenticated ? 1 : 0

  service  = google_cloud_run_service.this.name
  location = google_cloud_run_service.this.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

variable "name" {
  description = "Nombre del servicio Cloud Run"
  type        = string
}

variable "image" {
  description = "Imagen Docker a desplegar (ej: gcr.io/PROJECT_ID/service:latest)"
  type        = string
}

variable "region" {
  description = "Región de Google Cloud"
  type        = string
}

variable "project" {
  description = "ID del proyecto en Google Cloud"
  type        = string
}

variable "container_port" {
  description = "Puerto del contenedor"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Entorno (development, staging, production)"
  type        = string
  default     = "production"
}

variable "environment_variables" {
  description = "Variables de entorno adicionales"
  type        = map(string)
  default     = {}
}

variable "cpu_limit" {
  description = "Límite de CPU (ej: '1000m' para 1 CPU)"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Límite de memoria (ej: '512Mi')"
  type        = string
  default     = "512Mi"
}

variable "concurrency" {
  description = "Concurrencia máxima por instancia"
  type        = number
  default     = 80
}

variable "timeout" {
  description = "Timeout en segundos"
  type        = number
  default     = 300
}

variable "min_instances" {
  description = "Número mínimo de instancias"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Número máximo de instancias"
  type        = number
  default     = 10
}

variable "allow_unauthenticated" {
  description = "Permitir acceso sin autenticación"
  type        = bool
  default     = false
}

output "service_url" {
  description = "URL del servicio Cloud Run"
  value       = google_cloud_run_service.this.status[0].url
}

output "service_name" {
  description = "Nombre del servicio"
  value       = google_cloud_run_service.this.name
}
