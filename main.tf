provider "aws" {
  region = "us-east-1"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f" ]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames    = true
}

module "k8s_control_plane_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "k8s-control-plane-sg"
  description = "Security group for K8s control plane"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "API server"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd server client api"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet API"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 10259
      to_port     = 10259
      protocol    = "tcp"
      description = "kube-scheduler"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 10257
      to_port     = 10257
      protocol    = "tcp"
      description = "kube-controller-manager"
      cidr_blocks = "10.0.1.0/24"
    },
  ]

  egress_rules = ["all-all"]
}

module "k8s_data_plane_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "k8s-data-plane-sg"
  description = "Security group for K8s data plane (worker nodes)"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet API"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 10256
      to_port     = 10256
      protocol    = "tcp"
      description = "kube-proxy"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NodePort Services"
      cidr_blocks = "10.0.1.0/24"
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "udp"
      description = "NodePort Services"
      cidr_blocks = "10.0.1.0/24"
    },
  ]

  egress_rules = ["all-all"]
}

module "k8s_inbound_ssh" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "k8s-inbound-ssh-sg"
  description = "Security group to allow SSH connection to K8s nodes"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH connection"
      cidr_blocks = "10.0.101.0/24"
    }
  ]
}

module "k8s_outbound_ssh" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "k8s-outbound-ssh-sg"
  description = "Security group to allow SSH connection to K8s nodes"
  vpc_id      = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Connect to nodes via SSH"
      cidr_blocks = "10.0.1.0/24"
    }
  ]
}

module "public_access_outbound_https" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "public-access-outbound-https"
  description = "Security Group to allow SSM connection to instance"
  vpc_id      = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS to anywhere for SSM"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_instance" "public_access" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    module.k8s_outbound_ssh.security_group_id,
    module.public_access_outbound_https.security_group_id
  ]
  subnet_id = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  tags = {
    Name = "public_access"
  }
}

resource "aws_instance" "control_plane" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    module.k8s_control_plane_sg.security_group_id,
    module.k8s_inbound_ssh.security_group_id
  ]
  subnet_id = module.vpc.private_subnets[0]
  tags = {
    Name = "master-node"
  }
}

resource "aws_instance" "data_plane" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    module.k8s_data_plane_sg.security_group_id,
    module.k8s_inbound_ssh.security_group_id
  ]
  subnet_id = module.vpc.private_subnets[0]
  tags = {
    Name = "${var.instance_name}-${count.index + 1}"
  }
}
