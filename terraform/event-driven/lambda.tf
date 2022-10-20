data "archive_file" "s1" {
  type        = "zip"
  source_file = "${path.module}/stageOne/a2.py"
  output_path = "${path.module}/stageOne/a2.py.zip"
}

resource "aws_lambda_function" "s1" {
  filename      = "${path.module}/stageOne/a2.py.zip"
  function_name = "stage-a2-lambda"
  role          = aws_iam_role.s1.arn
  handler       = "a2.lambda_handler"
  runtime       = "python3.9"
  layers = [aws_lambda_layer_version.l1.arn, aws_lambda_layer_version.l2.arn]
  environment {
    variables = {
      snsArn = aws_sns_topic.s1.arn
    }
  }
}

resource "aws_sns_topic" "s1" {
  name                        = "a3-sns-topic.fifo"
  fifo_topic                  = true
  content_based_deduplication = true
}



resource "aws_sqs_queue" "s1" {
  name                        = "a4-sqs-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perQueue"
}

resource "aws_sqs_queue_policy" "s1" {
  queue_url = aws_sqs_queue.s1.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "sqspolicy",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "sns.amazonaws.com"
        },
        "Action" : "SQS:SendMessage",
        "Resource" : "${aws_sqs_queue.s1.arn}",
        "Condition" : {
          "ArnLike" : {
            "aws:SourceArn" : "${aws_sns_topic.s1.arn}"
          }
        }
      }
    ]
  })
}


resource "aws_sns_topic_subscription" "s1" {
  topic_arn = aws_sns_topic.s1.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.s1.arn
}


data "aws_iam_policy_document" "s1" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [aws_sns_topic.s1.arn]
    sid       = "_sub_and_pub_"
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.s1.arn
  policy = data.aws_iam_policy_document.s1.json
}

data "aws_caller_identity" "current" {}


data "archive_file" "a2" {
  type        = "zip"
  source_file = "${path.module}/stageOne/a5.py"
  output_path = "${path.module}/stageOne/a5.py.zip"
}

resource "aws_lambda_function" "a5" {
  filename      = "${path.module}/stageOne/a5.py.zip"
  function_name = "stage-a5-lambda"
  role          = aws_iam_role.s1.arn
  handler       = "a5.lambda_handler"
  runtime       = "python3.9"
  layers = [aws_lambda_layer_version.l1.arn, aws_lambda_layer_version.l2.arn]
  environment {
    variables = {
      destination_bucket_name = aws_s3_bucket.s21.bucket                                              # abc1-bucket-s3
      replication_destination_bucket_name = aws_s3_bucket.s22.bucket                                  # "b1-bucket-s3"
      sqsUrl = aws_sqs_queue.s1.url                               
    }
  }
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_sqs_queue.s1.arn
  function_name    = aws_lambda_function.a5.arn
}