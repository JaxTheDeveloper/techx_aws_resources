# ─── CloudWatch Dashboard ─────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "dochub" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0; y = 0; width = 12; height = 6
        properties = {
          title  = "Lambda Errors"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "${var.project_name}-backend"],
            ["AWS/Lambda", "Errors", "FunctionName", "${var.project_name}-kb-sync"],
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12; y = 0; width = 12; height = 6
        properties = {
          title  = "Lambda Duration (ms)"
          period = 300
          stat   = "p99"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-backend"],
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0; y = 6; width = 12; height = 6
        properties = {
          title   = "Query Latency (custom metric)"
          period  = 300
          stat    = "Average"
          metrics = [["DocHub", "QueryLatencyMs"]]
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12; y = 6; width = 12; height = 6
        properties = {
          title  = "API Gateway Requests"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", "${aws_apigatewayv2_api.dochub.id}"],
            ["AWS/ApiGateway", "5XXError", "ApiId", "${aws_apigatewayv2_api.dochub.id}"],
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0; y = 12; width = 12; height = 6
        properties = {
          title  = "Lambda Invocations"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-backend"],
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-kb-sync"],
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "log"
        x      = 12; y = 12; width = 12; height = 6
        properties = {
          title   = "Backend Errors (last 1h)"
          region  = var.aws_region
          query   = "SOURCE '/aws/lambda/${var.project_name}-backend' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          view    = "table"
        }
      }
    ]
  })
}

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
