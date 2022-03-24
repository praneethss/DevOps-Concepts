provider "aws" {
  region = "us-east-1"
  profile = "MyAWS"
}

resource "aws_iam_user" "lb" {
  name = "loadbalancer"
  path = "/system/"
}

resource "aws_iam_user_policy" "lb_ro" {
    name = "ec2"
    user = aws_iam_user.lb.name
    policy = jsonencode({
            Version: "2012-10-17",
            "Statement": [{
            "Effect": "Allow",
            "Action": ["ec2:*"],
            "Resource": "*" }]
    })
}

resource "aws_iam_user_policy" "lb_row" {

    name = "s3"
    user = aws_iam_user.lb.name
    policy = jsonencode({
            Version: "2012-10-17",
            "Statement": [{
            "Effect": "Allow",
            "Action": ["s3:*"],
            "Resource": "*" }]
    })
}
