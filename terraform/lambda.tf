resource "aws_cloudwatch_log_group" "backend" {
  name              = "/aws/lambda/${var.project_name}-backend"
  retention_in_days = 7
  tags              = { Name = "${var.project_name}-backend-logs" }
}

resource "aws_cloudwatch_log_group" "kb_sync" {
  name              = "/aws/lambda/${var.project_name}-kb-sync"
  retention_in_days = 7
  tags              = { Name = "${var.project_name}-kb-sync-logs" }
}

# ─── Lambda ZIP sources ────────────────────────────────────────────────────────
# These are placeholder handlers. Replace with your real application code
# by pointing filename at a real zip, or use S3 source for larger packages.

data "archive_file" "backend" {
  type        = "zip"
  output_path = "${path.module}/lambda_zips/backend.zip"

  source {
    filename = "handler.py"
    content  = <<-EOF
      import json, os, boto3, base64
      from datetime import datetime, timezone

      dynamodb = boto3.resource("dynamodb")
      bedrock  = boto3.client("bedrock-agent-runtime")

      TABLE_NAME     = os.environ["DYNAMODB_TABLE"]
      KB_ID          = os.environ["BEDROCK_KB_ID"]
      AGENT_ID       = os.environ.get("BEDROCK_AGENT_ID", "")
      AGENT_ALIAS_ID = os.environ.get("BEDROCK_AGENT_ALIAS_ID", "")
      S3_BUCKET      = os.environ["S3_BUCKET"]
      MODEL_ARN      = os.environ["BEDROCK_MODEL_ARN"]

      s3_client = boto3.client("s3")
      table     = dynamodb.Table(TABLE_NAME)

      def _cors(body, status=200):
          return {
              "statusCode": status,
              "headers": {
                  "Content-Type": "application/json",
                  "Access-Control-Allow-Origin": "*",
                  "Access-Control-Allow-Headers": "Authorization,Content-Type",
                  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
              },
              "body": json.dumps(body),
          }

      def _tenant_id(event):
          """Extract tenant_id from validated Cognito JWT claims."""
          ctx    = event.get("requestContext", {})
          auth   = ctx.get("authorizer", {})
          claims = auth.get("jwt", {}).get("claims", {})
          groups = claims.get("cognito:groups", "")
          # Use first group as tenant — matches Pre-Token-Gen Lambda logic
          if groups:
              return groups.split(",")[0]
          # Fallback: custom attribute
          return claims.get("custom:tenant_id", "default")

      def handle_upload(event, tenant_id):
          body    = json.loads(event.get("body") or "{}")
          doc_id  = body.get("doc_id")
          s3_key  = f"{tenant_id}/{doc_id}"
          # Presigned URL so frontend uploads directly to S3
          url = s3_client.generate_presigned_url(
              "put_object",
              Params={"Bucket": S3_BUCKET, "Key": s3_key, "ContentType": "application/pdf"},
              ExpiresIn=300,
          )
          # Write metadata to DynamoDB
          table.put_item(Item={
              "pk":          tenant_id,
              "sk":          f"DOC#{doc_id}",
              "tenant_id":   tenant_id,
              "doc_id":      doc_id,
              "s3_key":      s3_key,
              "filename":    body.get("filename", doc_id),
              "doc_type":    body.get("doc_type", "contract"),
              "uploaded_at": datetime.now(timezone.utc).isoformat(),
              "status":      "pending_ingestion",
          })
          return _cors({"upload_url": url, "doc_id": doc_id})

      def handle_query(event, tenant_id):
          body     = json.loads(event.get("body") or "{}")
          question = body.get("question", "")
          # Retrieve-and-generate with tenant_id metadata filter
          cw = boto3.client("cloudwatch")
          t0 = datetime.now(timezone.utc)
          resp = bedrock.retrieve_and_generate(
              input={"text": question},
              retrieveAndGenerateConfiguration={
                  "type": "KNOWLEDGE_BASE",
                  "knowledgeBaseConfiguration": {
                      "knowledgeBaseId": KB_ID,
                      "modelArn": MODEL_ARN,
                      "retrievalConfiguration": {
                          "vectorSearchConfiguration": {
                              "numberOfResults": 5,
                              "filter": {
                                  "equals": {
                                      "key":   "tenant_id",
                                      "value": tenant_id,
                                  }
                              },
                          }
                      },
                  },
              },
          )
          latency_ms = int((datetime.now(timezone.utc) - t0).total_seconds() * 1000)
          cw.put_metric_data(
              Namespace="DocHub",
              MetricData=[{
                  "MetricName": "QueryLatencyMs",
                  "Value":      latency_ms,
                  "Unit":       "Milliseconds",
              }],
          )
          answer   = resp["output"]["text"]
          citations = [
              c["retrievedReferences"][0]["location"]["s3Location"]["uri"]
              for c in resp.get("citations", [])
              if c.get("retrievedReferences")
          ]
          return _cors({"answer": answer, "citations": citations, "latency_ms": latency_ms})

      def handle_list_docs(event, tenant_id):
          result = table.query(
              IndexName="TenantUploadedAtIndex",
              KeyConditionExpression="tenant_id = :tid",
              ExpressionAttributeValues={":tid": tenant_id},
              ScanIndexForward=False,
          )
          return _cors({"docs": result.get("Items", [])})

      def lambda_handler(event, context):
          method = event.get("requestContext", {}).get("http", {}).get("method", "")
          path   = event.get("rawPath", "")
          if method == "OPTIONS":
              return _cors({})
          tenant_id = _tenant_id(event)
          if path == "/health":
              return _cors({"status": "ok", "tenant_id": tenant_id})
          if path == "/upload" and method == "POST":
              return handle_upload(event, tenant_id)
          if path == "/query" and method == "POST":
              return handle_query(event, tenant_id)
          if path == "/docs/list" and method == "GET":
              return handle_list_docs(event, tenant_id)
          return _cors({"error": "Not found"}, 404)
    EOF
  }
}

data "archive_file" "kb_sync" {
  type        = "zip"
  output_path = "${path.module}/lambda_zips/kb_sync.zip"

  source {
    filename = "handler.py"
    content  = <<-EOF
      import json, os, boto3

      bedrock    = boto3.client("bedrock-agent")
      KB_ID      = os.environ["BEDROCK_KB_ID"]
      DS_ID      = os.environ["BEDROCK_DS_ID"]
      dynamodb   = boto3.resource("dynamodb")
      TABLE_NAME = os.environ["DYNAMODB_TABLE"]

      def lambda_handler(event, context):
          """
          Triggered by EventBridge when a new object lands in S3.
          Starts a Bedrock KB ingestion job so the new doc becomes searchable.
          Also updates the DynamoDB item status to 'ingesting'.
          """
          detail  = event.get("detail", {})
          s3_key  = detail.get("object", {}).get("key", "")
          # s3_key format: tenant_id/doc_id
          parts   = s3_key.split("/", 1)
          if len(parts) < 2:
              print(f"Skipping key with unexpected format: {s3_key}")
              return

          tenant_id, doc_id = parts[0], parts[1]

          # Start ingestion job
          resp = bedrock.start_ingestion_job(
              knowledgeBaseId=KB_ID,
              dataSourceId=DS_ID,
          )
          job_id = resp["ingestionJob"]["ingestionJobId"]

          # Update metadata status
          table = dynamodb.Table(TABLE_NAME)
          table.update_item(
              Key={"pk": tenant_id, "sk": f"DOC#{doc_id}"},
              UpdateExpression="SET #s = :s, ingestion_job_id = :j",
              ExpressionAttributeNames={"#s": "status"},
              ExpressionAttributeValues={":s": "ingesting", ":j": job_id},
          )
          print(json.dumps({"tenant_id": tenant_id, "doc_id": doc_id, "job_id": job_id}))
          return {"job_id": job_id}
    EOF
  }
}

data "archive_file" "pre_token_gen" {
  type        = "zip"
  output_path = "${path.module}/lambda_zips/pre_token_gen.zip"

  source {
    filename = "handler.py"
    content  = <<-EOF
      def lambda_handler(event, context):
          groups = (
              event.get("request", {})
              .get("groupConfiguration", {})
              .get("groupsToOverride", [])
          )
          if groups:
              event["response"]["claimsOverrideDetails"] = {
                  "claimsToAddOrOverride": {
                      "cognito:groups": ",".join(groups)
                  }
              }
          return event
    EOF
  }
}

# ─── Backend Lambda (FastAPI / Mangum or plain handler) ───────────────────────

resource "aws_lambda_function" "backend" {
  function_name    = "${var.project_name}-backend"
  role             = aws_iam_role.lambda_exec_role.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.backend.output_path
  source_code_hash = data.archive_file.backend.output_base64sha256
  timeout          = var.lambda_timeout_sec
  memory_size      = var.lambda_memory_mb

  vpc_config {
    subnet_ids         = [aws_subnet.vpc_az1_private_app.id, aws_subnet.vpc_az2_private_app.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DYNAMODB_TABLE         = aws_dynamodb_table.dochub_docs.name
      S3_BUCKET              = aws_s3_bucket.documents.bucket
      BEDROCK_KB_ID          = aws_bedrockagent_knowledge_base.dochub.id
      BEDROCK_AGENT_ID       = aws_bedrockagent_agent.dochub.agent_id
      BEDROCK_AGENT_ALIAS_ID = aws_bedrockagent_agent_alias.dochub.agent_alias_id
      BEDROCK_MODEL_ARN      = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_foundation_model_id}"
      AWS_REGION_NAME        = var.aws_region
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.backend,
    aws_iam_role_policy.lambda_permissions,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]

  tags = { Name = "${var.project_name}-backend" }
}

# ─── KB Sync Lambda (EventBridge → Bedrock ingestion) ─────────────────────────

resource "aws_lambda_function" "kb_sync" {
  function_name    = "${var.project_name}-kb-sync"
  role             = aws_iam_role.lambda_exec_role.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.kb_sync.output_path
  source_code_hash = data.archive_file.kb_sync.output_base64sha256
  timeout          = 120
  memory_size      = 256

  vpc_config {
    subnet_ids         = [aws_subnet.vpc_az1_private_app.id, aws_subnet.vpc_az2_private_app.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.dochub_docs.name
      BEDROCK_KB_ID  = aws_bedrockagent_knowledge_base.dochub.id
      BEDROCK_DS_ID  = aws_bedrockagent_data_source.dochub.data_source_id
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.kb_sync,
    aws_iam_role_policy.lambda_permissions,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]

  tags = { Name = "${var.project_name}-kb-sync" }
}

# ─── Pre-Token Generation Lambda (Cognito trigger) ────────────────────────────

resource "aws_lambda_function" "pre_token_gen" {
  function_name    = "${var.project_name}-pre-token-gen"
  role             = aws_iam_role.lambda_exec_role.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.pre_token_gen.output_path
  source_code_hash = data.archive_file.pre_token_gen.output_base64sha256
  timeout          = 10
  memory_size      = 128

  # No VPC needed — Cognito triggers don't require it
  tags = { Name = "${var.project_name}-pre-token-gen" }
}

resource "aws_lambda_permission" "cognito_pre_token" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_token_gen.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.dochub.arn
}

resource "aws_lambda_permission" "eventbridge_kb_sync" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kb_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_to_kb_sync.arn
}
