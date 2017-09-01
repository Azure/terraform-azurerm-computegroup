provider "azurerm" {
    version = "~> 0.1"
}

module "loadbalancer" {
  source = "github.com/Azure/terraform-azurerm-loadbalancer"
  resource_group_name = "${ var.resource_group_name }"
  location = "${var.location}"
  lb_port = "${var.lb_port}"
  prefix = "${ var.resource_group_name }"
}

module "os" {
  source = "./os"
  vm_os_simple = "${ var.vm_os_simple }"
}

resource "azurerm_resource_group" "vmss" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
  tags     = "${var.tags}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.1.0/24"
}


resource "azurerm_virtual_machine_scale_set" "vm-linux" {
  count               = "${ replace("${var.vm_os_simple}${var.vm_os_offer}", "Server", "") == "Windows" ? 0 : 1 }"
  name                = "vmscaleset"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  upgrade_policy_mode = "Manual"
  tags                = "${var.tags}"

  sku {
    name     = "${var.vm_size}"
    tier     = "Standard"
    capacity = "${var.nb_instance}"
  }

  storage_profile_image_reference {
    id        = "${var.vm_os_id }"
    publisher = "${coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher)}"
    offer     = "${coalesce(var.vm_os_offer, module.os.calculated_value_os_offer)}"
    sku       = "${coalesce(var.vm_os_sku, module.os.calculated_value_os_sku)}"
    version   = "${var.vm_os_version}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${ var.managed_disk_type }"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "vmss"
    admin_username       = "${var.admin_username}"
    admin_password       = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_key}")}"
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      subnet_id                              = "${azurerm_subnet.subnet1.id}"
      load_balancer_backend_address_pool_ids = ["${module.loadbalancer.azurerm_lb_backend_address_pool_id}"]
    }
  }
}

resource "azurerm_virtual_machine_scale_set" "vm-windows" {
  count               = "${ replace("${var.vm_os_simple}${var.vm_os_offer}", "Server", "") == "Windows" ? 1 : 0 }"
  name                = "vmscaleset"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  upgrade_policy_mode = "Manual"
  tags                = "${var.tags}"

  sku {
    name     = "${var.vm_size}"
    tier     = "Standard"
    capacity = "${var.nb_instance}"
  }

  storage_profile_image_reference {
    id        = "${ var.vm_os_id }"
    publisher = "${ coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher) }"
    offer     = "${ coalesce(var.vm_os_offer, module.os.calculated_value_os_offer) }"
    sku       = "${ coalesce(var.vm_os_sku, module.os.calculated_value_os_sku) }"
    version   = "${ var.vm_os_version }"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${ var.managed_disk_type }"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "vmss"
    admin_username       = "${var.admin_username}"
    admin_password       = "${var.admin_password}"
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      subnet_id                              = "${azurerm_subnet.subnet1.id}"
      load_balancer_backend_address_pool_ids = ["${module.loadbalancer.azurerm_lb_backend_address_pool_id}"]
    }
  }
}