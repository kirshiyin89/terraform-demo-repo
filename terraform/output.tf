# Output the repository URLs
output "repository_urls" {
  value = {
    for name, repo in github_repository.repos : name => repo.html_url
  }
}
