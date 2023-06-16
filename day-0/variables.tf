variable "token" {
  sensitive = true
}

variable "name" {
  type        = string
  description = "The name used for naming servers"
}

variable "instances" {
  type        = number
  description = "The number of server instances to provision"
}