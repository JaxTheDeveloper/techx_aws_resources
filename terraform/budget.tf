# ─── SNS Topic for Budget Alerts ─────────────────────────────────────────────

resource "aws_sns_topic" "budget_alerts" {
  name = "${var.project_name}-budget-alerts"
  tags = { Name = "${var.project_name}-budget-alerts" }
}

resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.owner_email
}

# Allow AWS Budgets service to publish to this topic
resource "aws_sns_topic_policy" "budget_alerts" {
  arn = aws_sns_topic.budget_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowBudgetsSNSPublish"
      Effect = "Allow"
      Principal = {
        Service = "budgets.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.budget_alerts.arn
    }]
  })
}

# ─── AWS Budget ($100 cap, alert at 80%) ──────────────────────────────────────

resource "aws_budgets_budget" "dochub" {
  name         = "${var.project_name}-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert at 80% of limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_alert_pct
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  # Second alert at 100% (hard cap breach warning)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  # Forecasted spend alert at 80% — early warning
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_alert_pct
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }
}
