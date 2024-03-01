resource "aws_sqs_queue" "queries" {
  name = "${local.name}-queries"
}

resource "aws_sqs_queue_policy" "queries" {
  queue_url = aws_sqs_queue.queries.url
  policy    = data.aws_iam_policy_document.queries.json
}

data "aws_iam_policy_document" "queries" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.queries.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_iam_role.superset_task.arn]
    }
  }
}
