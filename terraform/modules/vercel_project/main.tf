# Módulo para crear proyectos de Vercel
# Basado en documentación oficial del Terraform Registry (noviembre 2025)

resource "vercel_project" "this" {
  name      = var.name
  framework = var.framework

  # Git Repository (opcional)
  dynamic "git_repository" {
    for_each = var.git_repository != null ? [var.git_repository] : []
    content {
      type             = git_repository.value.type
      repo             = git_repository.value.repo
      production_branch = lookup(git_repository.value, "production_branch", null)

      # Deploy hooks (opcional)
      dynamic "deploy_hooks" {
        for_each = lookup(git_repository.value, "deploy_hooks", [])
        content {
          name = deploy_hooks.value.name
          ref  = deploy_hooks.value.ref
        }
      }
    }
  }

  # Root directory (opcional)
  root_directory = var.root_directory != "" ? var.root_directory : null

  # Build configuration (opcional)
  build_command              = var.build_command != "" ? var.build_command : null
  install_command            = var.install_command != "" ? var.install_command : null
  output_directory          = var.output_directory != "" ? var.output_directory : null
  dev_command               = var.dev_command != "" ? var.dev_command : null
  ignore_command            = var.ignore_command != "" ? var.ignore_command : null

  # Build machine type
  build_machine_type = var.build_machine_type != "" ? var.build_machine_type : null

  # Node version
  node_version = var.node_version != "" ? var.node_version : null

  # Team ID (opcional)
  team_id = var.team_id != "" ? var.team_id : null

  # Environment variables (opcional, usar vercel_project_environment_variable para mejor gestión)
  dynamic "environment" {
    for_each = var.environment_variables
    content {
      key        = environment.value.key
      value      = environment.value.value
      target     = lookup(environment.value, "target", ["production", "preview"])
      sensitive  = lookup(environment.value, "sensitive", false)
      git_branch = lookup(environment.value, "git_branch", null)
      comment    = lookup(environment.value, "comment", null)
    }
  }

  # Auto-assign custom domains
  auto_assign_custom_domains = var.auto_assign_custom_domains

  # Preview deployments
  preview_deployments_disabled = var.preview_deployments_disabled

  # Git settings
  git_fork_protection = var.git_fork_protection
  git_lfs            = var.git_lfs

  # Git comments (opcional)
  dynamic "git_comments" {
    for_each = var.git_comments != null ? [var.git_comments] : []
    content {
      on_commit      = git_comments.value.on_commit
      on_pull_request = git_comments.value.on_pull_request
    }
  }

  # Public source
  public_source = var.public_source

  # Customer success code visibility
  customer_success_code_visibility = var.customer_success_code_visibility
}

