data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "company_s3" {
  statement {
    sid       = "ListOwnPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.payroll_docs.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["companies/*"]
    }
  }

  statement {
    sid       = "ManageOwnObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.payroll_docs.arn}/companies/*"]
  }
}

data "aws_iam_policy_document" "bureau_s3" {
  statement {
    sid       = "ListOwnPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.payroll_docs.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["bureaus/*"]
    }
  }

  statement {
    sid       = "ManageOwnObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.payroll_docs.arn}/bureaus/*"]
  }
}

data "aws_iam_policy_document" "employee_s3" {
  statement {
    sid       = "ListOwnPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.payroll_docs.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["employees/*"]
    }
  }

  statement {
    sid       = "ManageOwnObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.payroll_docs.arn}/employees/*"]
  }
}

resource "aws_iam_role" "company_portal" {
  name               = "${local.name_prefix}-company-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role" "bureau_portal" {
  name               = "${local.name_prefix}-bureau-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role" "employee_portal" {
  name               = "${local.name_prefix}-employee-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_policy" "company_s3" {
  name   = "${local.name_prefix}-company-s3"
  policy = data.aws_iam_policy_document.company_s3.json
}

resource "aws_iam_policy" "bureau_s3" {
  name   = "${local.name_prefix}-bureau-s3"
  policy = data.aws_iam_policy_document.bureau_s3.json
}

resource "aws_iam_policy" "employee_s3" {
  name   = "${local.name_prefix}-employee-s3"
  policy = data.aws_iam_policy_document.employee_s3.json
}

resource "aws_iam_role_policy_attachment" "company_s3" {
  role       = aws_iam_role.company_portal.name
  policy_arn = aws_iam_policy.company_s3.arn
}

resource "aws_iam_role_policy_attachment" "bureau_s3" {
  role       = aws_iam_role.bureau_portal.name
  policy_arn = aws_iam_policy.bureau_s3.arn
}

resource "aws_iam_role_policy_attachment" "employee_s3" {
  role       = aws_iam_role.employee_portal.name
  policy_arn = aws_iam_policy.employee_s3.arn
}

resource "aws_iam_instance_profile" "company_portal_profile" {
  name = "${local.name_prefix}-company-profile"
  role = aws_iam_role.company_portal.name
}

resource "aws_iam_instance_profile" "bureau_portal_profile" {
  name = "${local.name_prefix}-bureau-profile"
  role = aws_iam_role.bureau_portal.name
}

resource "aws_iam_instance_profile" "employee_portal_profile" {
  name = "${local.name_prefix}-employee-profile"
  role = aws_iam_role.employee_portal.name
}

locals {
  tenant_runtime_parameter_arns = {
    companies = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.parameter_base_path}/shared/db/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.parameter_base_path}/companies/*"
    ]
    bureaus = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.parameter_base_path}/shared/db/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.parameter_base_path}/bureaus/*"
    ]
    employees = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.parameter_base_path}/shared/db/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.parameter_base_path}/employees/*"
    ]
  }

  tenant_role_names = {
    companies = aws_iam_role.company_portal.name
    bureaus   = aws_iam_role.bureau_portal.name
    employees = aws_iam_role.employee_portal.name
  }
}

resource "aws_iam_policy" "tenant_ssm_runtime" {
  for_each = local.tenant_runtime_parameter_arns

  name = "${local.name_prefix}-${each.key}-ssm-runtime"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadRuntimeParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = each.value
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tenant_ssm_runtime" {
  for_each = local.tenant_role_names

  role       = each.value
  policy_arn = aws_iam_policy.tenant_ssm_runtime[each.key].arn
}