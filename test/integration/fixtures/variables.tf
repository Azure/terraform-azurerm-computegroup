variable "location" {}
variable "ssh_key" {}

variable "resource_group_name" {
  default = "terraform-test"
}

variable "vm_os_simple" {}

variable "vnet_subnet_id" {}

variable "load_balancer_backend_address_pool_ids" {}
