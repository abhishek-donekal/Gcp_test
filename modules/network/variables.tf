variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  description = "Base name for the VPC, subnet and firewall rules."
  type        = string
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}

variable "enable_nat" {
  description = "Cloud NAT gives the VMs outbound internet (apt, pip). Costs roughly $1/day, so it is off by default. Private Google Access still lets VMs reach GCS without it."
  type        = bool
  default     = false
}
