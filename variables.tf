variable "ami_id" {
  # Amazon Linux 2023 AMI 2023.10.20260330.0 x86_64 HVM kernel-6.1
  description = "ID of AMI to be used for EC2 instances"
  type        = string
  default     = "ami-01b14b7ad41e17ba4"
}

variable "instance_count" {
  description = "Amount of EC2 instances"
  type        = number
  default     = 2
}

variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "worker-node"
}

variable "instance_type" {
  description = "The EC2 instance's type."
  type        = string
  default     = "t3.micro"
}
