# Variables para el módulo de Vercel Project

variable "name" {
  description = "Nombre del proyecto en Vercel"
  type        = string
}

variable "framework" {
  description = "Framework del proyecto (ej: 'nextjs', 'react', 'vue', 'svelte', etc.)"
  type        = string
  default     = ""
}

variable "root_directory" {
  description = "Directorio raíz del proyecto (relativo al repo o absoluto)"
  type        = string
  default     = ""
}

# Git Repository (opcional)
variable "git_repository" {
  description = "Configuración del repositorio Git conectado al proyecto"
  type = object({
    type             = string
    repo             = string
    production_branch = optional(string)
    deploy_hooks = optional(list(object({
      name = string
      ref  = string
    })))
  })
  default = null
  validation {
    condition     = var.git_repository == null ? true : contains(["github", "gitlab", "bitbucket"], var.git_repository.type)
    error_message = "git_repository.type debe ser 'github', 'gitlab' o 'bitbucket'"
  }
}

# Build configuration
variable "build_command" {
  description = "Comando de build (si se omite, se detecta automáticamente)"
  type        = string
  default     = ""
}

variable "install_command" {
  description = "Comando de instalación (si se omite, se detecta automáticamente)"
  type        = string
  default     = ""
}

variable "output_directory" {
  description = "Directorio de salida del build (si se omite, se detecta automáticamente)"
  type        = string
  default     = ""
}

variable "dev_command" {
  description = "Comando de desarrollo (si se omite, se detecta automáticamente)"
  type        = string
  default     = ""
}

variable "ignore_command" {
  description = "Comando para determinar si se necesita un nuevo build basado en SHA"
  type        = string
  default     = ""
}

variable "build_machine_type" {
  description = "Tipo de máquina de build: 'enhanced' o 'turbo'"
  type        = string
  default     = ""
  validation {
    condition     = var.build_machine_type == "" || contains(["enhanced", "turbo"], var.build_machine_type)
    error_message = "build_machine_type debe ser 'enhanced' o 'turbo'"
  }
}

variable "node_version" {
  description = "Versión de Node.js para builds y serverless functions"
  type        = string
  default     = ""
}

# Team ID (opcional)
variable "team_id" {
  description = "Team ID de Vercel (opcional, para teams)"
  type        = string
  default     = ""
}

# Environment variables (opcional)
variable "environment_variables" {
  description = "Variables de entorno del proyecto (mejor usar vercel_project_environment_variable para gestión avanzada)"
  type = list(object({
    key        = string
    value      = string
    target     = optional(list(string), ["production", "preview"])
    sensitive  = optional(bool, false)
    git_branch = optional(string)
    comment    = optional(string)
  }))
  default = []
}

# Auto-assign custom domains
variable "auto_assign_custom_domains" {
  description = "Auto-asignar dominios custom después de cada deployment de producción"
  type        = bool
  default     = true
}

# Preview deployments
variable "preview_deployments_disabled" {
  description = "Deshabilitar creación de preview deployments"
  type        = bool
  default     = false
}

# Git settings
variable "git_fork_protection" {
  description = "Proteger forks de Git (requiere autorización para PRs con env vars o cambios en vercel.json)"
  type        = bool
  default     = true
}

variable "git_lfs" {
  description = "Habilitar soporte de Git LFS"
  type        = bool
  default     = false
}

# Git comments
variable "git_comments" {
  description = "Configuración de comentarios de Git"
  type = object({
    on_commit      = bool
    on_pull_request = bool
  })
  default = null
}

# Public source
variable "public_source" {
  description = "Hacer público el código fuente en /_logs y /_src"
  type        = bool
  default     = false
}

# Customer success code visibility
variable "customer_success_code_visibility" {
  description = "Permitir que Vercel Customer Support inspeccione el código fuente"
  type        = bool
  default     = false
}

