resource "cloudflare_worker_script" "this" {
  account_id = var.account_id
  name       = var.name
  content    = var.script
  # NOTA: cloudflare_worker_script (sin 's') NO soporta bindings directamente
  # Los bindings se deben configurar manualmente en Cloudflare Dashboard
  # o usar cloudflare_workers_script (con 's') que está DEPRECATED pero sí tiene bindings
  # Para producción, considerar usar cloudflare_worker_version con bindings
}

resource "cloudflare_worker_route" "this" {
  count = var.route_pattern != "" ? 1 : 0

  zone_id     = var.zone_id
  pattern     = var.route_pattern
  script_name = cloudflare_worker_script.this.name
}

variable "account_id" {
  description = "Account ID de Cloudflare"
  type        = string
}

variable "name" {
  description = "Nombre del Worker"
  type        = string
}

variable "script" {
  description = "Contenido del script del Worker (JavaScript/TypeScript)"
  type        = string
}

variable "zone_id" {
  description = "Zone ID para el routing (opcional)"
  type        = string
  default     = ""
}

variable "route_pattern" {
  description = "Patrón de ruta para el Worker (ej: api.example.com/*)"
  type        = string
  default     = ""
}

variable "plain_text_bindings" {
  description = "Bindings de texto plano"
  type = list(object({
    name = string
    text = string
  }))
  default = []
}

variable "secret_text_bindings" {
  description = "Nombres de bindings secretos (configurar manualmente en Dashboard)"
  type        = list(string)
  default     = []
}

variable "kv_namespace_bindings" {
  description = "Bindings de KV Namespaces"
  type = list(object({
    name         = string
    namespace_id = string
  }))
  default = []
}

output "worker_id" {
  description = "ID del Worker creado"
  value       = cloudflare_worker_script.this.id
}

output "worker_name" {
  description = "Nombre del Worker"
  value       = cloudflare_worker_script.this.name
}
