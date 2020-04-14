# variables.tf


variable "win_username" {
    description = "Username for Windows VM instance"
    type = string
    default = "devadmin"
}

variable "win_password" {
    description = "Password for Windows VM instance"
    type = string
}