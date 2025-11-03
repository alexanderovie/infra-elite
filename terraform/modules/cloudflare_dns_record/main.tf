resource "cloudflare_record" "this" {
  zone_id = var.zone_id
  name    = var.name
  type    = var.type
  content = var.content
  ttl     = var.ttl
  proxied = var.proxied

  # Opcional: Prioridad para registros MX o SRV
  priority = var.priority

  # Opcional: Comentario
  comment = var.comment != "" ? var.comment : null
}

variable "zone_id" {
  description = "Zone ID del dominio en Cloudflare"
  type        = string
}

variable "name" {
  description = "Nombre del registro DNS (ej: 'api' o '@' para raíz)"
  type        = string
}

variable "type" {
  description = "Tipo de registro DNS (A, AAAA, CNAME, MX, TXT, etc.)"
  type        = string
}

variable "content" {
  description = "Contenido del registro DNS"
  type        = string
}

variable "ttl" {
  description = "TTL del registro en segundos (1 = auto, 120-2147483647)"
  type        = number
  default     = 1
}

variable "proxied" {
  description = "Si el registro debe estar bajo el proxy de Cloudflare"
  type        = bool
  default     = false
}

variable "priority" {
  description = "Prioridad del registro (para MX, SRV)"
  type        = number
  default     = null
}

variable "comment" {
  description = "Comentario del registro"
  type        = string
  default     = ""
}

output "record_id" {
  description = "ID del registro DNS creado"
  value       = cloudflare_record.this.id
}

output "record_name" {
  description = "Nombre completo del registro"
  value       = cloudflare_record.this.hostname
}
