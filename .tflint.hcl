# Terraform Linting Configuration
# See .devcontainer/TOOLS.md for detailed documentation

config {
  # Enable module inspection
  module = true

  # Force tflint to check all files, not just those in the current directory
  force = false

  # Disable rules that are too strict for our use case
  disabled_by_default = false
}

# AWS Provider Plugin (if using AWS)
# plugin "aws" {
#   enabled = true
#   version = "0.29.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
# }

# General Terraform rules
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = false  # Optional - can enable if you want to enforce documentation
}

rule "terraform_documented_variables" {
  enabled = false  # Optional - can enable if you want to enforce documentation
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = false  # Can enable with custom conventions if needed
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = false  # Can enable if following standard module structure
}

rule "terraform_workspace_remote" {
  enabled = true
}

