output "vms" {
  value = module.compute.instance_names
}

output "vm_service_accounts" {
  value = module.compute.service_account_emails
}

output "buckets" {
  value = module.buckets.names
}

output "ssh_commands" {
  value = {
    for k, name in module.compute.instance_names :
    k => "gcloud compute ssh ${name} --zone ${module.compute.instance_zones[k]} --tunnel-through-iap --project ${local.project_id}"
  }
}
