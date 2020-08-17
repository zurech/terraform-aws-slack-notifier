provider "aws" {
  region = "us-east-2"
}

module "slack_notifier" {
  source            = "../"
  environment       = "development"
  slack_channel     = "monitoring"
  ssm_slack_webhook = "/slack_notifier/webhook"
}

resource "aws_lambda_permission" "slack_notifier" {
  statement_id  = "AllowExecutionFromSNSAle"
  action        = "lambda:InvokeFunction"
  function_name = module.slack_notifier.lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}

resource "aws_sns_topic" "sns_topic" {
  name = "slack-notifications-topic"
}

resource "aws_sns_topic_subscription" "slack_notifier" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = module.slack_notifier.lambda_arn
}
