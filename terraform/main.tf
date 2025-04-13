terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}


  # List of repositories to create with their specific customizations
  repositories = {
    "service-a" = {
      description = "Microservice A for customer data processing"
      topics      = ["microservice", "customer-data"]
      template    = null
    },
    "service-b" = {
      description = "Microservice B for order processing"
      topics      = ["microservice", "order-processing"]
      template    = null
    },
    "frontend-app" = {
      description = "Main frontend application"
      topics      = ["frontend", "react"]
      template    = null
    },
    "documentation" = {
      description = "Central documentation repository"
      topics      = ["docs", "markdown"]
      template    = null
    },
    "shared-libraries" = {
      description = "Shared code libraries and utilities"
      topics      = ["library", "shared-code"]
      template    = null
    }
  }
}

# Create repositories with standard settings and customizations
resource "github_repository" "repos" {
  for_each = local.repositories
  
  name        = each.key
  description = each.value.description
  
  # Merge standard settings with any repo-specific overrides
  visibility           = local.standard_settings.visibility
  has_issues           = local.standard_settings.has_issues
  has_projects         = local.standard_settings.has_projects
  has_wiki             = local.standard_settings.has_wiki
  allow_merge_commit   = local.standard_settings.allow_merge_commit
  allow_squash_merge   = local.standard_settings.allow_squash_merge
  allow_rebase_merge   = local.standard_settings.allow_rebase_merge
  delete_branch_on_merge = local.standard_settings.delete_branch_on_merge
  vulnerability_alerts = local.standard_settings.vulnerability_alerts
  auto_init            = local.standard_settings.auto_init
  
  # Apply template if specified
  dynamic "template" {
    for_each = each.value.template != null ? [each.value.template] : []
    content {
      owner      = template.value.owner
      repository = template.value.name
    }
  }
  
  # Combine standard topics with repo-specific topics
  topics = concat(local.standard_topics, each.value.topics)
}

# Apply standard branch protection to all repositories
resource "github_branch_protection" "main_branch" {
  for_each = github_repository.repos

  repository_id = each.value.name
  pattern       = "main"
  
  required_pull_request_reviews {
    required_approving_review_count = local.standard_branch_protection.required_approving_review_count
    dismiss_stale_reviews           = local.standard_branch_protection.dismiss_stale_reviews
    require_code_owner_reviews      = local.standard_branch_protection.require_code_owner_reviews
  }
  
  allows_force_pushes        = local.standard_branch_protection.allow_force_pushes
  allows_deletions           = local.standard_branch_protection.allow_deletions
}

# Create a .github/CODEOWNERS file in each repository
resource "github_repository_file" "codeowners" {
  for_each = github_repository.repos
  
  repository     = each.value.name
  branch         = "main"
  file           = ".github/CODEOWNERS"
  content        = "# Default code owners for this repository\n* @${var.github_owner}/admins\n"
  commit_message = "Add CODEOWNERS file"
  commit_author  = "Terraform"
  commit_email   = "terraform@example.com"
  
  # Wait for repository initialization
  depends_on = [github_repository.repos]
}



