resource "cloudflare_worker_script" "this" {
  account_id = var.account_id
  name       = var.name
  content    = var.script

  # Bindings usando el campo 'bindings' (lista de objetos)
  # Según documentación oficial: bindings requiere name, type, y opcionalmente text/namespace_id/etc
  bindings = concat(
    # Plain text bindings
    [
      for binding in var.plain_text_bindings : {
        name = binding.name
        type = "plain_text"
        text = binding.text
      }
    ],
    # Secret text bindings (solo nombre, el valor se configura en Dashboard o con cloudflare_worker_secret)
    [
      for secret_name in var.secret_text_bindings : {
        name = secret_name
        type = "secret_text"
        # No incluir 'text' para secret_text - se configura manualmente
      }
    ],
    # KV namespace bindings
    [
      for binding in var.kv_namespace_bindings : {
        name         = binding.name
        type         = "kv_namespace"
        namespace_id = binding.namespace_id
      }
    ]
  )
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
