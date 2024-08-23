resource "aws_s3_bucket" "quizzes" {
  bucket = "kmflow-org-quizzes"
  force_destroy = true
}