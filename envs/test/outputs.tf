output "vms" {
  value = module.app-us.vms
}

output "vm_service_accounts" {
  value = module.app-us.vm_service_accounts
}

output "buckets" {
  value = module.app-us.buckets
}

output "ssh_commands" {
  value = module.app-us.ssh_commands
}
