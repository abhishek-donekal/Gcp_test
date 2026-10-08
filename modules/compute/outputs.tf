output "instance_names" {
  value = { for k, i in google_compute_instance.this : k => i.name }
}

output "instance_zones" {
  value = { for k, i in google_compute_instance.this : k => i.zone }
}

output "service_account_emails" {
  description = "VM key => SA email."
  value       = { for k, sa in google_service_account.vm : k => sa.email }
}
