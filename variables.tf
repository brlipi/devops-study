variable "instance_count" {
  description = "Amount of EC2 instances"
  type        = number
  default     = 2
}

variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "learn-terraform"
}

variable "instance_type" {
  description = "The EC2 instance's type."
  type        = string
  default     = "t3.micro"
}
