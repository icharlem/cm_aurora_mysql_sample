# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aurora-mysql-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Aurora Configuration
variable "aurora_engine_version" {
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.04.0"
  validation {
    condition = can(regex("^8\\.0\\.mysql_aurora\\.", var.aurora_engine_version))
    error_message = "Aurora engine version must be 8.0.mysql_aurora.x.x.x format."
  }
}

variable "instance_class" {
  description = "Instance class for Aurora cluster instances"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of instances in the Aurora cluster"
  type        = number
  default     = 2
}

# Database Configuration
variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "myapp"
}

variable "master_username" {
  description = "Master username for the Aurora cluster"
  type        = string
  default     = "admin"
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Security Configuration
variable "deletion_protection" {
  description = "Enable deletion protection for Aurora cluster"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting Aurora cluster"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}
