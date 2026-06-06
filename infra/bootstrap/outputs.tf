output "state_bucket_name" {
  description = "S3 bucket name — use this as 'bucket' in the infra/ backend config."
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "DynamoDB lock table name — use this as 'dynamodb_table' in the infra/ backend config."
  value       = aws_dynamodb_table.terraform_locks.name
}
