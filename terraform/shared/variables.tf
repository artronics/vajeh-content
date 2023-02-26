variable "project" {
  type        = string
  description = "Project name. It should be the same as repo name. The value comes from PROJECT in .env file."
}

variable "account_zone" {
  type        = string
  description = "It's the root zone name of the account"
}
