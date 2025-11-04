# Módulo para crear proyectos de Vercel
# Basado en documentación oficial del Terraform Registry (noviembre 2025)

resource "vercel_project" "this" {
  name      = var.name
  framework = var.framework != "" ? var.framework : null

  # Git Repository (opcional) - NO es un bloque dynamic, es un atributo
  git_repository = var.git_repository != null ? {
    type             = var.git_repository.type
    repo             = var.git_repository.repo
    production_branch = lookup(var.git_repository, "production_branch", null)
    deploy_hooks     = lookup(var.git_repository, "deploy_hooks", null)
  } : null

  # Root directory (opcional)
  root_directory = var.root_directory != "" ? var.root_directory : null

  # Build configuration (opcional)
  build_command     = var.build_command != "" ? var.build_command : null
  install_command   = var.install_command != "" ? var.install_command : null
  output_directory  = var.output_directory != "" ? var.output_directory : null
  dev_command       = var.dev_command != "" ? var.dev_command : null
  ignore_command    = var.ignore_command != "" ? var.ignore_command : null

  # Node version
  node_version = var.node_version != "" ? var.node_version : null

  # Team ID (opcional)
  team_id = var.team_id != "" ? var.team_id : null

  # Auto-assign custom domains
  auto_assign_custom_domains = var.auto_assign_custom_domains

  # Git settings
  git_fork_protection = var.git_fork_protection
  git_lfs            = var.git_lfs

  # Git comments (opcional) - NO es un bloque dynamic, es un atributo
  git_comments = var.git_comments != null ? {
    on_commit      = var.git_comments.on_commit
    on_pull_request = var.git_comments.on_pull_request
  } : null

  # Public source
  public_source = var.public_source

  # Customer success code visibility
  customer_success_code_visibility = var.customer_success_code_visibility
}

# Nota: Las variables de entorno se deben gestionar con recursos separados:
# - vercel_project_environment_variable (una variable)
# - vercel_project_environment_variables (múltiples variables)
# NO se pueden usar en el recurso vercel_project directamente
