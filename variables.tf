variable "region" {
  description = "AWS region"
  type = string
}

variable "vpc_name" {
  description = "VPC name"
  type = string
}

variable "domain_name" {
  description = "Hosted zone domain name"
  type = string
}

variable "web_domain_name" {
  description = "VPC 365 fully qualified domain name"
  type = string
}

variable "vpc_cidr" {
  description = "VPC cidr address block"
  type = string
}

variable "availability_zones" {
  description = "VPC list of region availability zones"
  type = list(string)
}

variable "public_subnets" {
  description = "List of private VPC subnets cidr's"
  type = list(string)
}

variable "private_subnets" {
  description = "List of private VPC subnets cidr's"
  type = list(string)
}

variable "elb_name" {
  description = "Load Balancer name"
  type = string
}
