variable "location" {
  description = "Azure location name for NGINXaaS deployment."
  default     = "westeurope"
}

variable "name" {
  description = "Name of NGINXaaS deployment and related resources."
  default     = "nginx-demo-tf"
}

variable "tags" {
  description = "Tags for NGINXaaS deployment and related resources."
  type        = map(any)
  default = {
    env = "production"
  }
}
