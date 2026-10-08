variable "project_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

# --- naming: <prefix>-<env>-<market>-<app>-<purpose>-<zone letter>-<increment>
variable "name_prefix" {
  type    = string
  default = "g"
}

variable "environment_code" {
  description = "Short env code, e.g. tst."
  type        = string
}

variable "market_code" {
  description = "Short market code, e.g. us."
  type        = string
}

variable "application" {
  description = "Short app name, e.g. app."
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "iap_members" {
  description = "Users/groups who may SSH in (get serviceAccountUser on each VM SA, which OS Login requires)."
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "Metadata applied to EVERY instance in this call."
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Delivered via metadata[\"startup-script\"] so edits update the VM in place instead of recreating it."
  type        = string
  default     = ""
}

variable "enable_snapshots" {
  type    = bool
  default = true
}

variable "snapshot_retention_days" {
  type    = number
  default = 3
}

variable "gce_instances" {
  description = "VM key => settings. Adding a key adds a VM; existing VMs are untouched."
  type = map(object({
    zone              = string
    increment         = string # e.g. "001"
    purpose           = optional(string, "general")
    machine_type      = optional(string, "e2-micro")
    boot_disk_image   = optional(string, "debian-cloud/debian-12")
    boot_disk_size_gb = optional(number, 20)
    boot_disk_type    = optional(string, "pd-standard")
    additional_disks = optional(list(object({
      device_name = string # shows up as /dev/disk/by-id/google-<device_name>
      size_gb     = number
      type        = optional(string, "pd-standard")
    })), [])
  }))
}
