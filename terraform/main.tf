data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default"{
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}


resource "aws_iam_role" "ec2_s3_access_role"{ 

   name = "cloudserver-s3-role"
   assume_role_policy = jsonencode({
   Version = "2012-10-17"
   Statement = [{
   Action = "sts:AssumeRole"
   Effect = "Allow"
   Principal = {
    Service = "ec2.amazonaws.com"
   }
   }]
      })

}

resource "aws_iam_role_policy_attachment" "s3_read_policy"{
    
    role = aws_iam_role.ec2_s3_access_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_profile"{
    
    name = "cloudserver-s3-profile"
    role = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_security_group" "web_sg" {
    name = "cloudserver-web-sg"
    vpc_id = data.aws_vpc.default.id


ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

egress {
    
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
}
}

data "aws_ami" "amazon_linux" {
    most_recent = true 
    owners = ["amazon"]
    filter {
        name ="name"
        values = ["al2023-ami-2023.*-x86_64"]
    }
}

resource "aws_launch_template" "app_template" {
    name_prefix = "cloudserver-template"
    image_id = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_s3_profile.name
    }
    user_data = filebase64("${path.module}/userdata.sh")
}
 
resource "aws_autoscaling_group" "app_asg" {
    name = "cloudserver-asg"
    vpc_zone_identifier = data.aws_subnets.default.ids
    desired_capacity = 1
    min_size = 1
    max_size = 2
    launch_template {
        id =aws_launch_template.app_template.id
        version = "$Latest"
    }
} 