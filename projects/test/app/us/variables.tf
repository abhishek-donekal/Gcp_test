variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "iap_members" {
  description = "e.g. [\"user:you@gmail.com\"]"
  type        = list(string)
}

variable "enable_nat" {
  type    = bool
  default = false
}
