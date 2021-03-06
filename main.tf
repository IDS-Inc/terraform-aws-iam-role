module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.1.3"
  attributes = "${var.attributes}"
  delimiter  = "${var.delimiter}"
  name       = "${var.name}"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${var.principals_arns}"]
    }
  }
}

module "aggregated_policy" {
  source           = "git::https://github.com/cloudposse/terraform-aws-iam-policy-document-aggregator.git?ref=tags/0.1.0"
  source_documents = ["${var.policy_documents}"]
}

resource "aws_iam_policy" "default" {
  count       = "${var.enabled == "true" ? 1 : 0}"
  name        = "${module.label.id}"
  description = "Allow S3 actions"
  policy      = "${module.aggregated_policy.result_document}"
}

resource "aws_iam_role" "default" {
  count                = "${var.enabled == "true" ? 1 : 0}"
  name                 = "${module.label.id}"
  assume_role_policy   = "${data.aws_iam_policy_document.assume_role.json}"
  description          = "IAM Role with permissions to perform actions on S3 resources"
  max_session_duration = "${var.max_session_duration}"
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  role       = "${aws_iam_role.default.name}"
  policy_arn = "${aws_iam_policy.default.arn}"
}
