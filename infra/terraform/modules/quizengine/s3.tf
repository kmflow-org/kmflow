resource "aws_s3_bucket" "artifacts" {
  bucket = "kmflow-org-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket" "quizzes" {
  bucket = "kmflow-org-quizzes"
  force_destroy = true
}