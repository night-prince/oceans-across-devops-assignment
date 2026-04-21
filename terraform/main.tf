locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CostProfile = "free-tier-safe-thinking"
  }

  effective_tenant_instances = length(var.tenant_instances) > 0 ? var.tenant_instances : {
    companies = {
      ami_id               = var.company_ami_id
      subnet_index         = 0
      iam_instance_profile = aws_iam_instance_profile.company_portal_profile.name
      name_suffix          = "companies"
      s3_prefix            = "companies/"
    }
    bureaus = {
      ami_id               = var.bureau_ami_id
      subnet_index         = 1
      iam_instance_profile = aws_iam_instance_profile.bureau_portal_profile.name
      name_suffix          = "bureaus"
      s3_prefix            = "bureaus/"
    }
    employees = {
      ami_id               = var.employee_ami_id
      subnet_index         = 0
      iam_instance_profile = aws_iam_instance_profile.employee_portal_profile.name
      name_suffix          = "employees"
      s3_prefix            = "employees/"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_instance" "tenant_portal" {
  for_each = local.effective_tenant_instances

  ami                         = each.value.ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public[each.value.subnet_index].id
  vpc_security_group_ids      = [aws_security_group.portal_ec2[each.key].id]
  iam_instance_profile        = each.value.iam_instance_profile
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.ec2_root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name   = "${local.name_prefix}-${each.value.name_suffix}"
    Tenant = each.key
    Tier   = "compute"
  }
}