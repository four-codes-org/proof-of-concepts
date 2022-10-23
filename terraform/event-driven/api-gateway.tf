resource "aws_api_gateway_rest_api" "api" {
  name        = var.apigateway 
  description = "This api to call sqs messages"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# resource "aws_api_gateway_resource" "root" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   path_part   = ""
# }

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id # aws_api_gateway_resource.root.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id # aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.get.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  credentials             = aws_iam_role.apigateway.arn
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${data.aws_caller_identity.account.account_id}/${aws_sqs_queue.c4.name}"
  request_parameters = {
    "integration.request.querystring.Action" = "'ReceiveMessage'"
  }
}

resource "aws_api_gateway_method_response" "get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id # aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id # aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.get.status_code
}



resource "aws_api_gateway_stage" "get" {
  deployment_id = aws_api_gateway_deployment.get.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "sqsQueueReader"
}

resource "aws_api_gateway_deployment" "get" {
  depends_on  = [aws_api_gateway_integration_response.get]
  rest_api_id = aws_api_gateway_rest_api.api.id
#   stage_name  = "sqsQueueReader"
}

resource "aws_wafv2_web_acl_association" "waf" {
  resource_arn = aws_api_gateway_stage.get.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}


resource "aws_cloudwatch_log_group" "log" {
  name = "${var.apigateway}-${aws_api_gateway_rest_api.api.id}/sqsQueueReader"
}

resource "aws_iam_role" "log" {
    name               = "${var.apigateway}-apigw-cw-role"
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "log" {
    name = "${var.apigateway}-cw-policy"
    role = aws_iam_role.cloudwatch.id
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams",
                    "logs:PutLogEvents",
                    "logs:GetLogEvents",
                    "logs:FilterLogEvents"
                ],
                "Resource": "*"
            }
        ]
    })
}

resource "aws_api_gateway_stage" "all" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.all.id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.yada.arn
    format          = <<EOF
{ "requestId":"$context.requestId", "ip": "$context.identity.sourceIp", "caller":"$context.identity.caller", "user":"$context.identity.user","requestTime":"$context.requestTime", "httpMethod":"$context.httpMethod","resourcePath":"$context.resourcePath", "status":"$context.status","protocol":"$context.protocol", "responseLength":"$context.responseLength" }
EOF
  }
}

resource "aws_api_gateway_method_settings" "post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.all.stage_name
  method_path = "${trimprefix(aws_api_gateway_resource.source.path, "/")}/${aws_api_gateway_method.post.http_method}"
  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_method_settings" "get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.all.stage_name
  method_path = "${trimprefix(aws_api_gateway_resource.source.path, "/")}/${aws_api_gateway_method.get.http_method}"
  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}
