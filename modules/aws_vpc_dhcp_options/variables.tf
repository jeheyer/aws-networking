variable "name" {
  type    = string
  default = null
}
variable "domain_name" {
  type    = string
  default = null
}
variable "dns_servers" {
  type    = list(string)
  default = null
}
variable "ntp_servers" {
  type    = list(string)
  default = null
}
variable "nbns_servers" {
  type    = list(string)
  default = null
}
