resource "aws_sqs_queue" "a4" {
  name                        = "a4-sqs-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perQueue"
}

resource "aws_sqs_queue_policy" "a4" {
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
        "Resource" : "${aws_sqs_queue.a4.arn}",
        "Condition" : {
          "ArnLike" : {
            "aws:SourceArn" : "${aws_sns_topic.a3.arn}"
          }
        }
      }
    ]
  })
}