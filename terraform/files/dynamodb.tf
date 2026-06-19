resource "aws_dynamodb_table" "dochub_docs" {
  name         = "${var.project_name}-docs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "tenant_id"
    type = "S"
  }

  attribute {
    name = "uploaded_at"
    type = "S"
  }

  # GSI: query all docs for a tenant sorted by upload time
  global_secondary_index {
    name            = "TenantUploadedAtIndex"
    hash_key        = "tenant_id"
    range_key       = "uploaded_at"
    projection_type = "ALL"
  }

  # CMK encryption at rest
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dochub_cmk.arn
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-docs"
    Environment = var.environment
  }
}
