variable "project" {
  type        = string
  description = "Project name. It should be the same as repo name. The value comes from PROJECT in .env file."
}

variable "workspace_tag" {
  type        = string
  description = "The tag value for the \"Workspace\". If it's user workspace then the pattern must be \"user_<short_code>. If it's PR then it must be pr_<pr_no>. Otherwise it's either \"dev\" or \"prod\""
}

variable "account_zone" {
  type        = string
  description = "It's the root zone name of the account"
}
