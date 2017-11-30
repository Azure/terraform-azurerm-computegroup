Deploys a group of Virtual Machines exposed to a public IP via a Load Balancer
==============================================================================

This Terraform module deploys a Virtual Machines Scale Set in Azure and opens the specified ports on the loadbalancer for external access and returns the id of the VM scale set deployed.

This module requires a network and loadbalancer to be provider separately. You can provision them with the "Azure/network/azurerm" and "Azure/loadbanacer/azurerm" modules.

Usage
-----

Using the `vm_os_simple`:

```hcl 
provider "azurerm" {
  version = "~> 0.3"
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
  "lb_port" {
      http = [ "80", "Tcp", "80"]
  }
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
    cmd_extension       = "sudo apt-get -y install nginx"
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
  version = "~> 0.3"
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
  "lb_port" {
      http = [ "80", "Tcp", "80"]
  }
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
    cmd_extension       = "sudo apt-get -y install nginx"
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

The module does not expose direct access to each node of the VM scale set for security reason. The following example shows how to use the compute group module with a jumpbox machine.

```hcl
provider "azurerm" {
  version = "~> 0.3"
}

variable "resource_group_name" {
    default = "jumpbox-test"
}

variable "location" { 
    default = "westus"
}

module "network" {
    source = "Azure/network/azurerm"
    location = "${var.location}"
    resource_group_name = "${var.resource_group_name}"
  }

module "loadbalancer" {
  source = "Azure/loadbalancer/azurerm"
  resource_group_name = "${var.resource_group_name}"
  location = "${var.location}"
  prefix = "terraform-test"
  "lb_port" {
      http = [ "80", "Tcp", "80"]
  }
}

module "computegroup" {
    source              = "Azure/computegroup/azurerm"
    resource_group_name = "${var.resource_group_name}"
    location            = "${var.location}"
    vm_size             = "Standard_DS1_v2"
    admin_username      = "azureuser"
    admin_password      = "ComplexPassword"
    ssh_key             = "~/.ssh/id_rsa.pub"
    nb_instance         = 2
    vm_os_publisher     = "Canonical"
    vm_os_offer         = "UbuntuServer"
    vm_os_sku           = "16.04-LTS"
    vnet_subnet_id      = "${module.network.vnet_subnets[0]}"
    load_balancer_backend_address_pool_ids = "${module.loadbalancer.azurerm_lb_backend_address_pool_id}"
    cmd_extension       = "sudo apt-get -y install nginx"
    lb_port             = {
                            http = ["80", "Tcp", "80"]
                          }
    tags                = {
                            environment = "codelab"
                          }
}

resource "azurerm_public_ip" "jumpbox" {
  name                         = "jumpbox-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.resource_group_name}-ssh"
  depends_on                   = ["module.network"]
  tags {
    environment = "codelab"
  }
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = "${module.network.vnet_subnets[0]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
  }

  tags {
    environment = "codelab"
  }
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "jumpbox"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox"
    admin_username = "azureuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  tags {
    environment = "codelab"
  }
}

````

Run Test
-----
### Requirements
- [Git](https://git-scm.com/downloads)
- [Ruby **(~> 2.3)**](https://www.ruby-lang.org/en/downloads/)
- [Bundler **(~> 1.15)**](https://bundler.io/)
- [Terraform **(~> 0.10.8)**](https://www.terraform.io/downloads.html)
- [Configure Terraform for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)
- [Generate and add SSH Key](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)(save the key in ~/.ssh/id_rsa)

### Quick Start
1. `bundle install`
2. `rake build`
3. `rake e2e`


Authors
=======
Originally created by [Damien Caro](http://github.com/dcaro)

License
=======

[MIT](LICENSE)
