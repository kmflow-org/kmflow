# IAM Role for EC2 Instances
resource "aws_iam_role" "quizengine_role" {
  name = "quizengine-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.quizengine_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Inline policy to allow S3 access
resource "aws_iam_role_policy" "s3_access" {
  name   = "quizengine-s3-access-policy"
  role   = aws_iam_role.quizengine_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.quizzes.arn}",
          "${aws_s3_bucket.quizzes.arn}/*",
        ]
      }
    ]
  })
}

# IAM Instance Profile for EC2 Instances
resource "aws_iam_instance_profile" "quizengine_instance_profile" {
  name = "quizengine-instance-profile"
  role = aws_iam_role.quizengine_role.name
}
