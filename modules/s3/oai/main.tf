data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.cloudfront_oai_iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_oai" {
  bucket = var.bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}
