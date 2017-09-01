output "vmss_name" {
  value = "${var.vm_os_simple == "Windows" ? azurerm_virtual_machine_scale_set.vm-windows.name : azurerm_virtual_machine_scale_set.vm-linux.name}"
}

output "vmss_id" {
  value = "${var.vm_os_simple == "Windows" ? azurerm_virtual_machine_scale_set.vm-windows.id : azurerm_virtual_machine_scale_set.vm-linux.id }}" 
}

output "vmss_public_ip" {
  value = "${var.vm_os_simple == "Windows" ? azurerm_virtual_machine_scale_set.vm-windows.public_ip : azurerm_virtual_machine_scale_set.vm-linux.public_ip }}" 
}
