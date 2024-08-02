variable "prefix" {
    type = string
}

variable "env" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "acm_certificate_arn" {
    type = string
}

variable "release_version" {
  type        = string
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "private_subnet_ids"{
  type = list
}

variable "public_subnet_ids"{
  type = list
}
