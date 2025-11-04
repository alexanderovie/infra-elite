# Outputs del módulo de Vercel Project

output "project_id" {
  description = "ID del proyecto creado"
  value       = vercel_project.this.id
}

output "project_name" {
  description = "Nombre del proyecto"
  value       = vercel_project.this.name
}

output "project_url" {
  description = "URL del proyecto (vercel.app)"
  value       = "https://${vercel_project.this.name}.vercel.app"
}

