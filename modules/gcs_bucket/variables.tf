variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  description = "Prepended to every bucket key. Bucket names are global, so include something unique (e.g. the project ID)."
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "buckets" {
  description = "Bucket key => settings. Key becomes the name suffix."
  type = map(object({
    storage_class      = optional(string, "STANDARD")
    versioning         = optional(bool, false)
    lifecycle_age_days = optional(number) # delete objects older than N days
    force_destroy      = optional(bool, true)
  }))
}

variable "writers" {
  description = "Bucket key => members that get objectAdmin + legacyBucketReader."
  type        = map(list(string))
  default     = {}
}
