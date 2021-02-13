variable api_description {
  description = "API Gateway REST API description."
  default     = ""
}

variable api_name {
  description = "API Gateway REST API name."
  default = "phony_adt_api"
}

variable api_timeout {
  description = "API Gateway integration timeout in milliseconds."
}

variable jwt_issuer {
  description = "Issuer for JWT generation."
}

variable jwt_secret {
}

variable valid_key {
}

variable aws_region {
}

variable lambda_role_name {
  description = "What do you want the AWS role for used by the lambda to be named?"
  default = "phony_adt_lambda_role"
}

variable lambda_function_name {
  description = "What do you want the lambda name to be?"
  default = "PhonyAdtLambda"
}

variable lambda_zip_file {
  description = "Location/Name of Zip file to deploy"
}