variable aws_region {
    default = "eu-west-2"
}

variable create_jira {
  description = "Set to false to disable creation of the Jira Commenter lambda"
  default     = true
}

variable lambda_loglevel {
    default = "INFO"
}

variable jira_apikey {
    default     = ""
    description = "Authentication key for Jira. If the service is Jira Cloud then this will be an API key, otherwise a user password"
}

variable jira_server {
    default     = ""
    description = "The Jira server URL"
}

variable jira_user {
    default     = ""
    description = "Username for Jira"
}

variable jira_verify {
    default     = false
    description = "Verify the Jira SSL certificate against a public CA"
}