# ─── OpenSearch Serverless – Encryption Policy ────────────────────────────────

resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "${lower(replace(var.project_name, "_", "-"))}-enc"
  type        = "encryption"
  description = "Encryption policy for DocHub vector collection"

  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${lower(replace(var.project_name, "_", "-"))}-vectors"]
    }]
    AWSOwnedKey = true
  })
}

# ─── OpenSearch Serverless – Network Policy ────────────────────────────────────

resource "aws_opensearchserverless_security_policy" "network" {
  name        = "${lower(replace(var.project_name, "_", "-"))}-net"
  type        = "network"
  description = "Network policy for DocHub vector collection"

  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${lower(replace(var.project_name, "_", "-"))}-vectors"]
      },
      {
        ResourceType = "dashboard"
        Resource     = ["collection/${lower(replace(var.project_name, "_", "-"))}-vectors"]
      }
    ]
    # Bedrock accesses OpenSearch Serverless via public endpoint with data access policy
    # This is normal for Bedrock KB integration
    AllowFromPublic = true
  }])
}

# ─── OpenSearch Serverless – Data Access Policy ────────────────────────────────

resource "aws_opensearchserverless_access_policy" "data" {
  name        = "${lower(replace(var.project_name, "_", "-"))}-data"
  type        = "data"
  description = "Data access for Bedrock KB role and Lambda"

  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index"
        Resource     = ["index/${lower(replace(var.project_name, "_", "-"))}-vectors/*"]
        Permission   = ["aoss:CreateIndex", "aoss:DeleteIndex", "aoss:UpdateIndex", "aoss:DescribeIndex", "aoss:ReadDocument", "aoss:WriteDocument"]
      },
      {
        ResourceType = "collection"
        Resource     = ["collection/${lower(replace(var.project_name, "_", "-"))}-vectors"]
        Permission   = ["aoss:CreateCollectionItems", "aoss:DeleteCollectionItems", "aoss:UpdateCollectionItems", "aoss:DescribeCollectionItems"]
      }
    ]
    Principal = [
      aws_iam_role.bedrock_kb_role.arn,
      aws_iam_role.lambda_exec_role.arn,
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    ]
  }])
}

# ─── OpenSearch Serverless Collection ─────────────────────────────────────────

resource "aws_opensearchserverless_collection" "vectors" {
  name        = "${lower(replace(var.project_name, "_", "-"))}-vectors"
  type        = "VECTORSEARCH"
  description = "DocHub KB vector store — minimum 2 OCU"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data
  ]

  tags = {
    Name        = "${var.project_name}-vectors"
    Environment = var.environment
  }
}
