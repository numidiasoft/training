workflow "Terraform" {
  resolves = "terraform-validate"
  on = "pull_request"
}

action "filter-to-pr-open-synced" {
  uses = "actions/bin/filter@master"
  args = "action 'opened|synchronize'"
}

action "terraform-fmt" {
  uses = "hashicorp/terraform-github-actions/fmt@v0.3.2"
  needs = "filter-to-pr-open-synced"
  secrets = ["GITHUB_TOKEN"]
  env = {
    TF_ACTION_WORKING_DIR = "./providers/aws/terraform/"
  }
}

action "terraform-init" {
  uses = "hashicorp/terraform-github-actions/init@v0.3.2"
  needs = "terraform-fmt"
  secrets = ["GITHUB_TOKEN"]
  env = {
    TF_ACTION_WORKING_DIR = "./providers/aws/terraform/"
  }
}

action "terraform-validate" {
  uses = "hashicorp/terraform-github-actions/validate@v0.3.2"
  needs = "terraform-init"
  secrets = ["GITHUB_TOKEN"]
  env = {
    TF_ACTION_WORKING_DIR = "./providers/aws/terraform/"
  }
}

## action "terraform-plan" {
##   uses = "hashicorp/terraform-github-actions/plan@v<latest version>"
##   needs = "terraform-validate"
##   secrets = ["GITHUB_TOKEN"]
##   env = {
##     TF_ACTION_WORKING_DIR = "./providers/aws/terraform/"
##     # If you're using Terraform workspaces, set this to the workspace name.
##     TF_ACTION_WORKSPACE = "default"
##   }
## }