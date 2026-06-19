# ─── Bedrock Knowledge Base ───────────────────────────────────────────────────

resource "aws_bedrockagent_knowledge_base" "dochub" {
  name        = "${var.project_name}-kb"
  description = "DocHub multi-tenant document knowledge base"
  role_arn    = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_embedding_model_id}"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.vectors.arn
      vector_index_name = "dochub-vectors"
      field_mapping {
        vector_field   = "embedding"
        text_field     = "text"
        metadata_field = "metadata"
      }
    }
  }

  tags = { Name = "${var.project_name}-kb" }

  depends_on = [
    aws_opensearchserverless_collection.vectors,
    aws_iam_role_policy.bedrock_kb_permissions,
  ]
}

# ─── KB Data Source (S3 document bucket) ──────────────────────────────────────

resource "aws_bedrockagent_data_source" "dochub" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.dochub.id
  name              = "${var.project_name}-s3-datasource"
  description       = "Tenant-isolated documents from S3"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.documents.arn
    }
  }

  # Chunking: fixed-size 512 tokens, 20% overlap
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 512
        overlap_percentage = 20
      }
    }
  }
}

# ─── Bedrock Agent ────────────────────────────────────────────────────────────

resource "aws_bedrockagent_agent" "dochub" {
  agent_name              = "${var.project_name}-agent"
  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn
  foundation_model        = var.bedrock_foundation_model_id
  description             = "DocHub document intelligence agent"
  idle_session_ttl_in_seconds = 600

  instruction = <<-PROMPT
    You are a document intelligence assistant for a multi-tenant SaaS platform.
    You only have access to documents belonging to the current user's organization.
    NEVER reference documents from other organizations.
    When answering, always cite the document name and the relevant section or clause.
    If you cannot find the answer in the available documents, say exactly:
    "I could not find this information in your organization's documents."
    Use the list_documents tool to find available documents by type before answering
    questions that reference specific document categories.
    Be precise — quote exact clause numbers or section headings when they appear in the source.
  PROMPT

  tags = { Name = "${var.project_name}-agent" }

  depends_on = [aws_iam_role_policy.bedrock_agent_permissions]
}

# ─── Agent Knowledge Base Association ────────────────────────────────────────

resource "aws_bedrockagent_agent_knowledge_base_association" "dochub" {
  agent_id             = aws_bedrockagent_agent.dochub.agent_id
  description          = "DocHub KB association"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.dochub.id
  knowledge_base_state = "ENABLED"
}

# ─── Agent Alias (stable invoke target) ───────────────────────────────────────

resource "aws_bedrockagent_agent_alias" "dochub" {
  agent_alias_name = "live"
  agent_id         = aws_bedrockagent_agent.dochub.agent_id
  description      = "Live alias for DocHub agent"

  tags = { Name = "${var.project_name}-agent-alias" }

  depends_on = [aws_bedrockagent_agent_knowledge_base_association.dochub]
}
