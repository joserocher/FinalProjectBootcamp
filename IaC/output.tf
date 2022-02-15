output "azure_project" {
  value = var.project_name
}

output "azure_invoice" {
  value = var.azure_invoice
}

output "environment" {
  value = var.environment
}

output "swarm" {
  value = azurerm_virtual_machine.swarm.*.name
}

output "swarm_private_ip_address" {
  value = azurerm_network_interface.swarm.*.private_ip_address
}

output "swarm_public_ip_address" {
  value = azurerm_public_ip.swarm.*.ip_address
}
output "swarm_data_disk" {
  value = azurerm_managed_disk.swarm.*.disk_size_gb
}
output "nfs" {
  value = azurerm_virtual_machine.nfs.*.name
}

output "nfs_private_ip_address" {
  value = azurerm_network_interface.nfs.*.private_ip_address
}

output "nfs_public_ip_address" {
  value = azurerm_public_ip.nfs.*.ip_address
}
output "nfs_data_disk" {
  value = azurerm_managed_disk.nfs.*.disk_size_gb
}

output "pgsql" {
  value = azurerm_virtual_machine.pgsql.*.name
}

output "pgsql_private_ip_address" {
  value = azurerm_network_interface.pgsql.*.private_ip_address
}

output "pgsql_public_ip_address" {
  value = azurerm_public_ip.pgsql.*.ip_address
}
output "pgsql_data_disk" {
  value = azurerm_managed_disk.pgsql.*.disk_size_gb
}

output "mysql" {
  value = azurerm_virtual_machine.mysql.*.name
}

output "mysql_private_ip_address" {
  value = azurerm_network_interface.mysql.*.private_ip_address
}

output "mysql_public_ip_address" {
  value = azurerm_public_ip.mysql.*.ip_address
}
output "mysql_data_disk" {
  value = azurerm_managed_disk.mysql.*.disk_size_gb
}

output "nifi" {
  value = azurerm_virtual_machine.nifi.*.name
}

output "nifi_private_ip_address" {
  value = azurerm_network_interface.nifi.*.private_ip_address
}

output "nifi_public_ip_address" {
  value = azurerm_public_ip.nifi.*.ip_address
}
output "nifi_data_disk" {
  value = azurerm_managed_disk.nifi.*.disk_size_gb
}

