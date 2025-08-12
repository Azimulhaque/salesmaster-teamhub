Here are the Terraform IaC configuration files for the 'SalesMaster & TeamHub' project, structured as requested.

---

### 1. main.tf

This file configures the AWS provider, specifies the required Terraform version, and sets up a placeholder S3 backend for state management.

```terraform
# main.tf

# Configure the Terraform version
terraform {
  required_version = ">= 1.0.0"

  # Configure the S3 backend for state management
  # Replace 'your-tf-state-bucket' and 'salesmaster-teamhub/terraform.tfstate'
  # with your actual S3 bucket name and desired key.
  # This bucket must exist prior to running 'terraform init'.
  backend "s3" {
    bucket         = "your-tf-state-bucket"
    key            = "salesmaster-teamhub/terraform.tfstate"
    region         = "us-east-1" # Ensure this matches your AWS region
    encrypt        = true
    dynamodb_table = "your-tf-state-lock-table" # Optional: for state locking
  }

  # Define required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible version
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# Data source to get available availability zones in the specified region
data "aws_availability_zones" "available" {
  state = "available"
}
```

---

### 2. variables.tf

This file defines all the input variables for the project, allowing for easy customization and reusability.

```terraform
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The base name for all resources in the project."
  type        = string
  default     = "salesmaster-teamhub"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Ensure these are within vpc_cidr
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"] # Ensure these are within vpc_cidr
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "salesmaster-eks"
}

variable "eks_node_group_instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "eks_node_group_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_group_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "eks_node_group_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "db_instance_type" {
  description = "RDS PostgreSQL instance type."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS database in GB."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for RDS."
  type        = string
  default     = "14.7"
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes for ElastiCache Redis."
  type        = number
  default     = 1
}
```

---

### 3. vpc.tf

This file defines the core networking components: VPC, subnets, internet gateway, NAT gateways, route tables, and essential security groups.

```terraform
# vpc.tf

# Create a new VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = "dev" # Or appropriate environment
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Project     = var.project_name
    Environment = "dev"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Project     = var.project_name
    Environment = "dev"
  }
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  vpc   = true

  tags = {
    Name    = "${var.project_name}-nat-eip-${count.index + 1}"
    Project = var.project_name
  }
}

# Create NAT Gateways in public subnets
resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name    = "${var.project_name}-nat-gw-${count.index + 1}"
    Project = var.project_name
  }
  # Ensure NAT Gateway is created after EIP is associated
  depends_on = [aws_internet_gateway.main]
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create private route tables (one per private subnet, pointing to its respective NAT Gateway)
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name    = "${var.project_name}-private-rt-${count.index + 1}"
    Project = var.project_name
  }
}

# Associate private route tables with private subnets
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group for EKS Cluster Control Plane and Nodes
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane and nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block] # Allow all traffic within VPC for simplicity, refine as needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-cluster-sg"
    Project = var.project_name
  }
}

# Security Group for RDS PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432 # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id] # Allow EKS nodes to connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

# Security Group for ElastiCache Redis
resource "aws_security_group" "elasticache_sg" {
  name        = "${var.project_name}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379 # Redis default port
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id] # Allow EKS nodes to connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-elasticache-sg"
    Project = var.project_name
  }
}
```

---

### 4. eks.tf

This file defines the EKS cluster, its associated IAM roles, and the worker node group.

```terraform
# eks.tf

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-eks-cluster-role"
    Project = var.project_name
  }
}

# Attach AmazonEKSClusterPolicy to the EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach AmazonEKSVPCResourceController to the EKS cluster role (for ENI management)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.project_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-eks-node-group-role"
    Project = var.project_name
  }
}

# Attach AmazonEKSWorkerNodePolicy to the EKS node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Attach AmazonEC2ContainerRegistryReadOnly to the EKS node group role
resource "aws_iam_role_policy_attachment" "eks_ecr_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# Attach AmazonEKS_CNI_Policy to the EKS node group role
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28" # Specify a desired EKS version

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.eks_cluster.id]
    endpoint_private_access = false # Set to true for private endpoint access only
    endpoint_public_access  = true
  }

  # Enable logging for control plane components (optional but recommended)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name    = "${var.project_name}-eks-cluster"
    Project = var.project_name
  }

  # Ensure the VPC components are created before the EKS cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller_policy,
    aws_security_group.eks_cluster
  ]
}

# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [for s in aws_subnet.private : s.id]
  instance_types  = [var.eks_node_group_instance_type]

  scaling_config {
    desired_size = var.eks_node_group_desired_size
    max_size     = var.eks_node_group_max_size
    min_size     = var.eks_node_group_min_size
  }

  # Optional: Associate a security group with the node group
  # remote_access {
  #   ec2_ssh_key = "your-ssh-key-name" # Replace with your key pair name
  #   source_security_groups = ["sg-xxxxxxxxxxxxxxxxx"] # Or your IP range
  # }

  # Optional: Add labels to nodes
  # labels = {
  #   env = "dev"
  # }

  # Optional: Add taints to nodes
  # taints {
  #   key    = "example-key"
  #   value  = "example-value"
  #   effect = "NO_SCHEDULE"
  # }

  tags = {
    Name    = "${var.project_name}-eks-node-group"
    Project = var.project_name
  }

  # Ensure the EKS cluster is created before the node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_ecr_read_only_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_eks_cluster.main
  ]
}
```

---

### 5. database.tf

This file defines the RDS PostgreSQL instance and the ElastiCache Redis cluster, along with their respective subnet groups.

```terraform
# database.tf

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id] # RDS should be in private subnets

  tags = {
    Name    = "${var.project_name}-rds-subnet-group"
    Project = var.project_name
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgresql" {
  identifier           = "${var.project_name}-postgresql"
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_type
  allocated_storage    = var.db_allocated_storage
  db_name              = "salesmasterdb" # Default database name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true # Set to false for production
  publicly_accessible  = false # Keep private for security
  multi_az             = false # Set to true for production for high availability
  storage_type         = "gp2" # General Purpose SSD

  tags = {
    Name    = "${var.project_name}-postgresql-db"
    Project = var.project_name
  }

  # Ensure security group is created before RDS instance
  depends_on = [aws_security_group.rds_sg]
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "${var.project_name}-elasticache-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id] # ElastiCache should be in private subnets

  tags = {
    Name    = "${var.project_name}-elasticache-subnet-group"
    Project = var.project_name
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_cache_nodes
  parameter_group_name = "default.redis6.x" # Or a specific version, e.g., "default.redis6.2"
  engine_version       = "6.x" # Or a specific version, e.g., "6.2"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids   = [aws_security_group.elasticache_sg.id]

  tags = {
    Name    = "${var.project_name}-redis-cache"
    Project = var.project_name
  }

  # Ensure security group is created before ElastiCache cluster
  depends_on = [aws_security_group.elasticache_sg]
}
```

---

### 6. s3.tf

This file defines the S3 bucket for user uploads with appropriate private access policies.

```terraform
# s3.tf

# S3 Bucket for user uploads
resource "aws_s3_bucket" "user_uploads" {
  bucket = "${var.project_name}-user-uploads" # S3 bucket names must be globally unique

  tags = {
    Name    = "${var.project_name}-user-uploads-bucket"
    Project = var.project_name
  }
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "user_uploads_block_public_access" {
  bucket = aws_s3_bucket.user_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Set ACL to private (default, but explicit for clarity)
resource "aws_s3_bucket_acl" "user_uploads_acl" {
  bucket = aws_s3_bucket.user_uploads.id
  acl    = "private"
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "user_uploads_versioning" {
  bucket = aws_s3_bucket.user_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "user_uploads_sse" {
  bucket = aws_s3_bucket.user_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optional: S3 Bucket Policy (if specific IAM roles need access)
# resource "aws_s3_bucket_policy" "user_uploads_policy" {
#   bucket = aws_s3_bucket.user_uploads.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect    = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_EKS_SERVICE_ACCOUNT_ROLE" # Replace with actual role ARN
#         },
#         Action    = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ],
#         Resource  = [
#           "${aws_s3_bucket.user_uploads.arn}/*",
#           aws_s3_bucket.user_uploads.arn
#         ]
#       }
#     ]
#   })
# }
```

---

### 7. outputs.tf

This file defines the outputs that will be displayed after Terraform applies the configuration, providing key information about the deployed resources.

```terraform
# outputs.tf

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [for s in aws_subnet.private : s.id]
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "eks_kubeconfig_arn" {
  description = "ARN of the EKS cluster for kubeconfig."
  value       = aws_eks_cluster.main.arn
}

output "rds_postgresql_endpoint" {
  description = "Endpoint address of the RDS PostgreSQL instance."
  value       = aws_db_instance.postgresql.address
}

output "rds_postgresql_port" {
  description = "Port of the RDS PostgreSQL instance."
  value       = aws_db_instance.postgresql.port
}

output "elasticache_redis_endpoint" {
  description = "Endpoint address of the ElastiCache Redis cluster."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "elasticache_redis_port" {
  description = "Port of the ElastiCache Redis cluster."
  value       = aws_elasticache_cluster.redis.port
}

output "s3_user_uploads_bucket_name" {
  description = "Name of the S3 bucket for user uploads."
  value       = aws_s3_bucket.user_uploads.id
}

output "s3_user_uploads_bucket_arn" {
  description = "ARN of the S3 bucket for user uploads."
  value       = aws_s3_bucket.user_uploads.arn
}
```