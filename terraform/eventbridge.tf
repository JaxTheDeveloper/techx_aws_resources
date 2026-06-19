# ─── EventBridge Rule: S3 Object Created → KB Sync ───────────────────────────

resource "aws_cloudwatch_event_rule" "s3_to_kb_sync" {
  name        = "${var.project_name}-s3-to-kb-sync"
  description = "Fires when a new document lands in the DocHub S3 bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.documents.bucket]
      }
      object = {
        # Only process PDF/DOCX uploads, not metadata sidecar files
        key = [{
          suffix = ".pdf"
          }, {
          suffix = ".docx"
          }, {
          suffix = ".txt"
        }]
      }
    }
  })

  tags = { Name = "${var.project_name}-s3-to-kb-sync" }
}

resource "aws_cloudwatch_event_target" "kb_sync_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_to_kb_sync.name
  target_id = "KBSyncLambda"
  arn       = aws_lambda_function.kb_sync.arn
}
