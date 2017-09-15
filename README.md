Deploys a group of Virtual Machines exposed to a public IP via a Load Balancer
==============================================================================

This Terraform module deploys a Virtual Machines Scale Set in Azure and opens the specified ports on the loadbalancer for external access and returns the id of the VM scale set deployed.

This module requires a network and loadbalancer to be provider separately. You can provision them with the "Azure/network/azurerm" and "Azure/loadbanacer/azurerm" modules.



Usage
-----

Using the `vm_os_simple`: 

```hcl 
provider "azurerm" {
  version = "~> 0.1"
}

variable "resource_group_name" {
    default = "terraform-test"
}

module "network" {
    source = "Azure/network/azurerm"
    location = "westus"
    resource_group_name = "${var.resource_group_name}"
  }

module "loadbalancer" {
  source = "Azure/loadbalancer/azurerm"
  resource_group_name = "${var.resource_group_name}"
  location = "westus"
  prefix = "terraform-test"
}

module "computegroup" { 
    source              = "Azure/computegroup/azurerm"
    resource_group_name = "${var.resource_group_name}"
    location            = "westus"
    vm_size             = "Standard_A0"
    admin_username      = "azureuser"
    admin_password      = "ComplexPassword"
    ssh_key             = "~/.ssh/id_rsa.pub"
    nb_instance         = 2
    vm_os_simple        = "UbuntuServer"
    vnet_subnet_id      = "${module.network.vnet_subnets[0]}"
    load_balancer_backend_address_pool_ids = "${module.loadbalancer.azurerm_lb_backend_address_pool_id}"
    lb_port             = { 
                            http = ["80", "Tcp", "80"]
                            https = ["443", "Tcp", "443"]
                          }
    tags                = {
                            environment = "dev"
                            costcenter  = "it"
                          }
}

output "vmss_id"{
  value = "${module.computegroup.vmss_id}"
}

```

Using the `vm_os_publisher`, `vm_os_offer` and `vm_os_sku` 

```hcl 

provider "azurerm" {
  version = "~> 0.1"
}

variable "resource_group_name" {
    default = "terraform-test"
}

module "network" {
    source = "Azure/network/azurerm"
    location = "westus"
    resource_group_name = "${var.resource_group_name}"
  }

module "loadbalancer" {
  source = "Azure/loadbanacer/azurerm"
  resource_group_name = "${var.resource_group_name}"
  location = "westus"
  prefix = "terraform-test"
}

module "computegroup" { 
    source              = "Azure/computegroup/azurerm"
    resource_group_name = "${var.resource_group_name}"
    location            = "westus"
    vm_size             = "Standard_A0"
    admin_username      = "azureuser"
    admin_password      = "ComplexPassword"
    ssh_key             = "~/.ssh/id_rsa.pub"
    nb_instance         = 2
    vm_os_publisher     = "Canonical"
    vm_os_offer         = "UbuntuServer"
    vm_os_sku           = "14.04.2-LTS"
    vnet_subnet_id      = "${module.network.vnet_subnets[0]}"
    load_balancer_backend_address_pool_ids = "${module.loadbalancer.azurerm_lb_backend_address_pool_id}"
    lb_port             = { 
                            http = ["80", "Tcp", "80"]
                            https = ["443", "Tcp", "443"]
                          }
    tags                = {
                            environment = "dev"
                            costcenter  = "it"
                          }
}

output "vmss_id"{
  value = "${module.computegroup.vmss_id}"
}

```


Authors
=======
Originally created by [Damien Caro](http://github.com/dcaro)

License
=======

[MIT](LICENSE)
