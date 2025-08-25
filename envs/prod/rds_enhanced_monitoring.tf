data "aws_iam_policy_document" "rds_em_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_em" {
  name               = "${var.name_prefix}-rds-em"
  assume_role_policy = data.aws_iam_policy_document.rds_em_trust.json
}

resource "aws_iam_role_policy_attachment" "rds_em_attach" {
  role       = aws_iam_role.rds_em.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
