# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.aurora_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.aurora_vpc.cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.aurora_private_subnets[*].id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.aurora_public_subnets[*].id
}

# Aurora Cluster Outputs
output "aurora_cluster_id" {
  description = "Aurora cluster ID"
  value       = aws_rds_cluster.aurora_mysql_cluster.cluster_identifier
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora_mysql_cluster.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora_mysql_cluster.reader_endpoint
}

output "aurora_cluster_port" {
  description = "Aurora cluster port"
  value       = aws_rds_cluster.aurora_mysql_cluster.port
}

output "aurora_cluster_database_name" {
  description = "Aurora cluster database name"
  value       = aws_rds_cluster.aurora_mysql_cluster.database_name
}

output "aurora_cluster_master_username" {
  description = "Aurora cluster master username"
  value       = aws_rds_cluster.aurora_mysql_cluster.master_username
  sensitive   = true
}

output "aurora_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.aurora_mysql_cluster.arn
}

output "aurora_cluster_resource_id" {
  description = "Aurora cluster resource ID"
  value       = aws_rds_cluster.aurora_mysql_cluster.cluster_resource_id
}

# Aurora Instance Outputs
output "aurora_instance_ids" {
  description = "List of Aurora instance IDs"
  value       = aws_rds_cluster_instance.aurora_cluster_instances[*].identifier
}

output "aurora_instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = aws_rds_cluster_instance.aurora_cluster_instances[*].endpoint
}

# Security Outputs
output "aurora_security_group_id" {
  description = "ID of the Aurora security group"
  value       = aws_security_group.aurora_sg.id
}

# KMS Outputs
output "kms_key_id" {
  description = "KMS key ID used for Aurora encryption"
  value       = aws_kms_key.aurora_kms_key.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for Aurora encryption"
  value       = aws_kms_key.aurora_kms_key.arn
}

# Secrets Manager Outputs
output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.aurora_master_password.arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.aurora_master_password.name
}

# Connection Information
output "connection_info" {
  description = "Database connection information"
  value = {
    endpoint    = aws_rds_cluster.aurora_mysql_cluster.endpoint
    port        = aws_rds_cluster.aurora_mysql_cluster.port
    database    = aws_rds_cluster.aurora_mysql_cluster.database_name
    username    = aws_rds_cluster.aurora_mysql_cluster.master_username
    secret_name = aws_secretsmanager_secret.aurora_master_password.name
  }
}
