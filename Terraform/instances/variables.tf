variable "avail_zone" {
  type = string

}

variable "env_prefix" {
  type = string

}

variable "instance_type" {
  type = string

}


variable "vpc_id" {
  type = string
}


variable "subnet_id" {
  type = string
}

variable "ansible-key-name" {
  type = string
}

variable "ansible-key-pem" {
  type = string
}


variable "bootstrap-key-name" {
  type = string
}

variable "bootstrap-key-pem" {
  type = string
}


variable "agent-key-name" {
  type = string
}

variable "agent-key-pem" {
  type = string
}

variable "ec2-role-profile-name" {
  type = string
}

variable "jenkins-chart-url" {
  type = string
}


variable "regapp-chart-url" {
  type = string
}
