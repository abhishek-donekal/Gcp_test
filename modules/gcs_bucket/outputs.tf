output "names" {
  description = "Bucket key => bucket name."
  value       = { for k, b in google_storage_bucket.this : k => b.name }
}

output "urls" {
  value = { for k, b in google_storage_bucket.this : k => b.url }
}
