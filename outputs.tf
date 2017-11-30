output "vmss_id" {
  value = "${concat(azurerm_virtual_machine_scale_set.vm-windows.*.id, azurerm_virtual_machine_scale_set.vm-linux.*.id)}"
}
