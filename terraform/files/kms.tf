resource "aws_kms_key" "dochub_cmk" {
  description             = "DocHub CMK for S3 and DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowLambdaRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_exec_role.arn
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowBedrockRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.bedrock_kb_role.arn
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "dochub_cmk_alias" {
  name          = "alias/${var.project_name}-cmk"
  target_key_id = aws_kms_key.dochub_cmk.key_id
}
