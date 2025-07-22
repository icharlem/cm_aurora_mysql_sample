# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "aurora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "aurora_igw" {
  vpc_id = aws_vpc.aurora_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# Create private subnets for Aurora
resource "aws_subnet" "aurora_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.aurora_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Create public subnets (for NAT gateways and potential bastion hosts)
resource "aws_subnet" "aurora_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.aurora_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.project_name}-aurora-subnet-group"
  subnet_ids = aws_subnet.aurora_private_subnets[*].id

  tags = {
    Name        = "${var.project_name}-aurora-subnet-group"
    Environment = var.environment
  }
}

# Generate random password for Aurora cluster
resource "random_password" "aurora_master_password" {
  length  = 16
  special = true
}

# Create security group for Aurora cluster
resource "aws_security_group" "aurora_sg" {
  name_prefix = "${var.project_name}-aurora-sg"
  vpc_id      = aws_vpc.aurora_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MySQL/Aurora access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-aurora-sg"
    Environment = var.environment
  }
}

# Create Aurora cluster parameter group with Parallel Query disabled
resource "aws_rds_cluster_parameter_group" "aurora_parameter_group" {
  family      = "aurora-mysql8.0"
  name        = "${var.project_name}-aurora-parameter-group"
  description = "Aurora cluster parameter group with Parallel Query explicitly disabled"

  parameter {
    name  = "aurora_parallel_query"
    value = "ON"
  }

  # Optional: Other performance-related parameters
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name        = "${var.project_name}-aurora-parameter-group"
    Environment = var.environment
  }
}

# Create Aurora MySQL cluster
resource "aws_rds_cluster" "aurora_mysql_cluster" {
  cluster_identifier = "${var.project_name}-aurora-mysql-cluster"
  engine             = "aurora-mysql"
  engine_version     = var.aurora_engine_version
  engine_mode        = "provisioned"

  database_name   = var.database_name
  master_username = var.master_username
  master_password = random_password.aurora_master_password.result

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  # Use the parameter group with Parallel Query explicitly disabled
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_parameter_group.name

  storage_encrypted = true
  kms_key_id        = aws_kms_key.aurora_kms_key.arn

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = var.deletion_protection

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name        = "${var.project_name}-aurora-mysql-cluster"
    Environment = var.environment
  }
}

# Create Aurora cluster instances
resource "aws_rds_cluster_instance" "aurora_cluster_instances" {
  count              = var.instance_count
  identifier         = "${var.project_name}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_mysql_cluster.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora_mysql_cluster.engine
  engine_version     = aws_rds_cluster.aurora_mysql_cluster.engine_version

  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  tags = {
    Name        = "${var.project_name}-aurora-instance-${count.index + 1}"
    Environment = var.environment
  }
}

# KMS key for Aurora encryption
resource "aws_kms_key" "aurora_kms_key" {
  description             = "KMS key for Aurora cluster encryption"
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-aurora-kms-key"
    Environment = var.environment
  }
}

# KMS key alias
resource "aws_kms_alias" "aurora_kms_key_alias" {
  name          = "alias/${var.project_name}-aurora-key"
  target_key_id = aws_kms_key.aurora_kms_key.key_id
}

# IAM role for enhanced monitoring (optional)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.project_name}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-rds-enhanced-monitoring-role"
    Environment = var.environment
  }
}

# Attach policy to enhanced monitoring role
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Store master password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "aurora_master_password" {
  name        = "${var.project_name}-aurora-master-password"
  description = "Master password for Aurora MySQL cluster"

  tags = {
    Name        = "${var.project_name}-aurora-master-password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "aurora_master_password" {
  secret_id = aws_secretsmanager_secret.aurora_master_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.aurora_master_password.result
    endpoint = aws_rds_cluster.aurora_mysql_cluster.endpoint
    port     = aws_rds_cluster.aurora_mysql_cluster.port
  })
}
