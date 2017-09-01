output "vmss_name_public" {
  value = "${var.vm_os_simple == "Windows" ? azurerm_virtual_machine_scale_set.vm-windows.name : azurerm_virtual_machine_scale_set.vm-linux.name}"
  # value = "${azurerm_virtual_machine_scale_set.vm-linux.name}"
}

output "vmss_id" {
  value = "${var.vm_os_simple == "Windows" ? azurerm_virtual_machine_scale_set.vm-windows.id : azurerm_virtual_machine_scale_set.vm-linux.id }}" 
  # value = "${azurerm_virtual_machine_scale_set.vm-linux.name}"
}

output "vnet_id" {
  value = "${azurerm_virtual_network.vnet.id}"
}

output "subnet_id" {
  value = "${azurerm_subnet.subnet1.id}"
}