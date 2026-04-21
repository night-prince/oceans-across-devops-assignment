variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Short project identifier used in names and tags."
  type        = string
  default     = "oceans-across-payroll"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Resource owner tag value."
  type        = string
  default     = "devops-assignment"
}

variable "vpc_cidr" {
  description = "CIDR block for the shared VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "At least two AZs used for public and private subnets."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. Must align 1:1 with availability_zones."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets. Must align 1:1 with availability_zones."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets. Must align 1:1 with availability_zones."
  type        = list(string)
  default     = ["10.20.21.0/24", "10.20.22.0/24"]
}

variable "allowed_admin_cidrs" {
  description = "CIDRs allowed to reach public administration ports on EC2. Keep tight."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ec2_instance_type" {
  description = "Instance type for tenant EC2 instances."
  type        = string
  default     = "t3.micro"
}

variable "ec2_root_volume_size" {
  description = "Root volume size in GiB for tenant EC2 instances."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "payrolldb"
}

variable "db_username" {
  description = "PostgreSQL admin username. Password must be supplied securely."
  type        = string
  default     = "payrolladmin"
}

variable "db_password" {
  description = "PostgreSQL admin password supplied via tfvars or environment variable."
  type        = string
  sensitive   = true
}

variable "company_ami_id" {
  description = "AMI for the Company portal EC2 instance."
  type        = string
}

variable "bureau_ami_id" {
  description = "AMI for the Bureau portal EC2 instance."
  type        = string
}

variable "employee_ami_id" {
  description = "AMI for the Employee portal EC2 instance."
  type        = string
}

variable "tenant_instances" {
  description = "Per-tenant compute definitions used to instantiate one EC2 instance per tenant type."
  type = map(object({
    ami_id               = string
    subnet_index         = number
    private_ip           = optional(string)
    iam_instance_profile = string
    name_suffix          = string
    s3_prefix            = string
  }))
  default = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 30
}

variable "alert_email_endpoint" {
  description = "Optional email address subscribed to the SNS critical alerts topic."
  type        = string
  default     = ""
}