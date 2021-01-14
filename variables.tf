variable vpc_id {
  type = string
}

variable name {
  type = string
  description = "project name"
}

variable env {
  type = string
}

variable region {
  type = string
  description = "AWS region name"
}

variable sg_id {
  type = string
  description = "private security group"
}

variable tags {
  type = map(string)
  description = "tags"
  default     = {}
}

variable subnet_ids {
  type = list(string)
  description = "subnet"
  default     = []
}

variable instance_type {
  type = string
  default = "t2.micro"
}

variable desired_capacity{
  type = number
  default = 2
  description ="for now need"
}
variable max_size{
  type = number
  default = 2
  description =""
}
variable min_size{
  type = number
  default = 0
  description =""
}

variable is_internal {
  type = bool
  default = true
  description ="internal neteork for NLB"
}

variable aws_key {
  type = string
}

variable aws_secrect {
  type = string
}

variable ssh_key {
  type = string
  default = "ecs_key"
  description =""
}

variable rabbit_user {
  type = string
  default = "admin"
  description =""
}

variable rabbit_pw {
  type = string
  default = "admin"
  description =""
}