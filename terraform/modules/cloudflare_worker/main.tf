resource "cloudflare_worker_script" "this" {
  account_id = var.account_id
  name       = var.name
  content    = var.script
  # NOTA: cloudflare_worker_script (sin 's') NO soporta bindings
  # Para bindings, usar recursos separados:
  # - cloudflare_worker_secret (para secret_text)
  # - cloudflare_worker_kv_namespace_binding (para KV)
  # O usar cloudflare_workers_script (con 's') que está DEPRECATED pero sí tiene bindings
}

# Secret text bindings (si se proporcionan)
resource "cloudflare_worker_secret" "this" {
  for_each = toset(var.secret_text_bindings)

  account_id = var.account_id
  script_name = cloudflare_worker_script.this.name
  name = each.value
  # El valor del secreto se configura manualmente en Cloudflare Dashboard
  # o usando el argumento 'secret_text' en este recurso
}

# KV namespace bindings (si se proporcionan)
resource "cloudflare_worker_kv_namespace_binding" "this" {
  for_each = {
    for idx, binding in var.kv_namespace_bindings : binding.name => binding
  }

  account_id = var.account_id
  script_name = cloudflare_worker_script.this.name
  name = each.value.name
  namespace_id = each.value.namespace_id
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
