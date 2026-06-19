# ─── CloudWatch Dashboard ─────────────────────────────────────────────────────

# ─── Alarms ───────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  tags = { Name = "${var.project_name}-alerts" }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.owner_email
}

resource "aws_cloudwatch_metric_alarm" "backend_errors" {
  alarm_name          = "${var.project_name}-backend-errors"
  alarm_description   = "Lambda runtime errors exceed threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.backend.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = { Name = "${var.project_name}-backend-errors-alarm" }
}

resource "aws_cloudwatch_metric_alarm" "high_query_latency" {
  alarm_name          = "${var.project_name}-high-query-latency"
  alarm_description   = "Query latency (custom metric) exceeded 10 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "QueryLatencyMs"
  namespace           = "DocHub"
  period              = 300
  statistic           = "Average"
  threshold           = 10000
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = { Name = "${var.project_name}-high-query-latency-alarm" }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-lambda-throttles"
  alarm_description   = "Lambda throttles detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.backend.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = { Name = "${var.project_name}-throttles-alarm" }
}

# ─── Saved Log Insights Query ─────────────────────────────────────────────────

resource "aws_cloudwatch_query_definition" "upload_patterns" {
  name = "${var.project_name}/upload-latency-per-5min"

  log_group_names = [
    aws_cloudwatch_log_group.backend.name,
    aws_cloudwatch_log_group.kb_sync.name,
  ]

  query_string = <<-QUERY
    fields @timestamp, @message, @duration
    | filter @message like /upload|ingestion/
    | stats avg(@duration) as avg_latency_ms,
            max(@duration) as max_latency_ms,
            count() as count
        by bin(5m)
    | sort @timestamp desc
  QUERY
}
