data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["vpc-365-scores"]
  }
  depends_on = [module.aws_vpc]
}


resource "aws_security_group" "custom_sg" {

    name = "custom-sg-365"
    description = "Allow SSH, HTTP, HTTPS inbound traffic"
    vpc_id = data.aws_vpc.existing.id

    ingress {
        description = "HTTPS from VPC"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress {
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

      ingress {
        description = "SSH from VPC"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "elb-custom-sg"
    }
    depends_on = [module.aws_vpc]
}
