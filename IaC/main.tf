terraform {
  backend "azurerm" {
    resource_group_name  = "REC_XXX"
    storage_account_name = "XXXterraform"
    container_name       = "pro"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.72.0"
    }
  }  
}

provider "azurerm" {
  subscription_id = var.azure_subs
  tenant_id       = var.azure_tenant
  features {}
}

##### COMMON ITEMS ##########
resource "azurerm_resource_group" "main" {
  name     = "REC-${var.project_name}"
  location = var.azure_location
}

resource "azurerm_network_security_group" "sg-nopublic" {
  name                = "sg-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_security_rule" "XXX" {
  name                        = "Only_XXX"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.allowed_ips
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.sg-nopublic.name
}

resource "azurerm_network_security_rule" "XXX_ping" {
  name                        = "Only_XXX_Ping"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.allowed_ips
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.sg-nopublic.name
}

resource "azurerm_network_security_rule" "waf" {
  name                        = "Only_WAF"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = var.allowed_ipswaf
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.sg-nopublic.name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-net"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["8.8.4.4", "8.8.8.8"]
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.project_name}-int"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = ["10.0.5.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.sg-nopublic.id
}

########## S W A R M ############### 

resource "azurerm_public_ip" "swarm" {
  count               = var.azure_replicas_swarm * var.azure_app
  name                = "${var.project_name}-swarm${count.index}-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.azure_public_ip_type
  domain_name_label   = "${var.project_name}-swarm${count.index}"
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_interface" "swarm" {
  count                     = var.azure_replicas_swarm * var.azure_app
  name                      = "${var.project_name}-swarm${count.index}-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  #network_security_group_id = azurerm_network_security_group.sg-nopublic.id

  ip_configuration {
    name                          = "${var.project_name}-swarm${count.index}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.priv_ip_swarm[count.index]
    public_ip_address_id          = element(azurerm_public_ip.swarm.*.id, count.index)
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine" "swarm" {
  count                 = var.azure_replicas_swarm * var.azure_app
  name                  = "${var.project_name}-swarm${count.index}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.swarm.*.id, count.index)]
  vm_size               = var.azure_vmsize_swarm
  #availability_set_id   = azurerm_availability_set.swarm.id

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true
  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.azure_vmpublisher
    offer     = var.azure_vmoffer
    sku       = var.azure_vmsku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.project_name}-swarm${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = "100"
  }
  os_profile {
    computer_name  = "${var.project_name}-swarm${count.index}"
    admin_username = var.username
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = var.ssh_file
      key_data = var.key
    }
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_managed_disk" "swarm" {
  count                = var.azure_replicas_swarm * var.azure_app
  name                 = "${var.project_name}-swarm${count.index}-disk1"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = var.azure_disktype_swarm
  create_option        = "Empty"
  disk_size_gb         = var.azure_diskgb_swarm
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "swarm" {
  count              = var.azure_replicas_swarm * var.azure_app
  managed_disk_id    = element(azurerm_managed_disk.swarm.*.id, count.index)
  virtual_machine_id = element(azurerm_virtual_machine.swarm.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

########## nfs ############### 

resource "azurerm_public_ip" "nfs" {
  count               = var.azure_app * var.azure_nfs
  name                = "${var.project_name}-nfs${count.index}-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.azure_public_ip_type
  domain_name_label   = "${var.project_name}-nfs${count.index}"
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_interface" "nfs" {
  count                     = var.azure_app * var.azure_nfs
  name                      = "${var.project_name}-nfs${count.index}-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "${var.project_name}-nfs${count.index}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.priv_ip_nfs[count.index]
    public_ip_address_id          = element(azurerm_public_ip.nfs.*.id, count.index)
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine" "nfs" {
  count                 = var.azure_app * var.azure_nfs
  name                  = "${var.project_name}-nfs${count.index}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.nfs.*.id, count.index)]
  vm_size               = var.azure_vmsize_nfs
  
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true
  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.azure_vmpublisher
    offer     = var.azure_vmoffer
    sku       = var.azure_vmsku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.project_name}-nfs${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = "100"
  }
  os_profile {
    computer_name  = "${var.project_name}-nfs${count.index}"
    admin_username = var.username
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = var.ssh_file
      key_data = var.key
    }
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_managed_disk" "nfs" {
  count                = var.azure_app * var.azure_nfs
  name                 = "${var.project_name}-nfs${count.index}-disk1"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = var.azure_disktype_nfs
  create_option        = "Empty"
  disk_size_gb         = var.azure_diskgb_nfs
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "nfs" {
  count              = var.azure_app * var.azure_nfs
  managed_disk_id    = element(azurerm_managed_disk.nfs.*.id, count.index)
  virtual_machine_id = element(azurerm_virtual_machine.nfs.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

########## pgsql ############### 

resource "azurerm_public_ip" "pgsql" {
  count               = var.azure_app
  name                = "${var.project_name}-pgsql${count.index}-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.azure_public_ip_type
  domain_name_label   = "${var.project_name}-pgsql${count.index}"
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_interface" "pgsql" {
  count                     = var.azure_app
  name                      = "${var.project_name}-pgsql${count.index}-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "${var.project_name}-pgsql${count.index}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.priv_ip_pgsql[count.index]
    public_ip_address_id          = element(azurerm_public_ip.pgsql.*.id, count.index)
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine" "pgsql" {
  count                 = var.azure_app
  name                  = "${var.project_name}-pgsql${count.index}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.pgsql.*.id, count.index)]
  vm_size               = var.azure_vmsize_pgsql
  
  lifecycle {
    prevent_destroy = false
  }
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true
  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.azure_vmpublisher
    offer     = var.azure_vmoffer
    sku       = var.azure_vmsku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.project_name}-pgsql${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = "100"
  }
  os_profile {
    computer_name  = "${var.project_name}-pgsql${count.index}"
    admin_username = var.username
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = var.ssh_file
      key_data = var.key
    }
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_managed_disk" "pgsql" {
  count                = var.azure_app
  name                 = "${var.project_name}-pgsql${count.index}-disk1"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = var.azure_disktype_pgsql
  create_option        = "Empty"
  disk_size_gb         = var.azure_diskgb_pgsql
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "pgsql" {
  count              = var.azure_app
  managed_disk_id    = element(azurerm_managed_disk.pgsql.*.id, count.index)
  virtual_machine_id = element(azurerm_virtual_machine.pgsql.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

########## nex ############### 

resource "azurerm_public_ip" "nex" {
  count               = var.azure_nexus
  name                = "${var.project_name}-nex${count.index}-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.azure_public_ip_type
  domain_name_label   = "${var.project_name}-nex${count.index}"
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_interface" "nex" {
  count                     = var.azure_nexus
  name                      = "${var.project_name}-nex${count.index}-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "${var.project_name}-nex${count.index}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.priv_ip_nex[count.index]
    public_ip_address_id          = element(azurerm_public_ip.nex.*.id, count.index)
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine" "nex" {
  count                 = var.azure_nexus
  name                  = "${var.project_name}-nex${count.index}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.nex.*.id, count.index)]
  vm_size               = var.azure_vmsize_nex
  
  lifecycle {
    prevent_destroy = false
  }
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true
  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

storage_image_reference {
    publisher = var.azurew_vmpublisher
    offer     = var.azurew_vmoffer
    sku       = var.azurew_vmsku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.project_name}-nex${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.azure_disktype_nex}"
  }
  os_profile {
    computer_name  = "${var.project_name}-nex${count.index}" # Windows limits computer name to 15 characteres
    admin_username = "${var.usernamew}"
    admin_password = "${var.adminpwdw}"
  }
    os_profile_windows_config {
    enable_automatic_upgrades = false
    provision_vm_agent = true   
  }


  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

########## mysql ############### 

resource "azurerm_public_ip" "mysql" {
  count               = var.azure_nexus
  name                = "${var.project_name}-mysql${count.index}-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.azure_public_ip_type
  domain_name_label   = "${var.project_name}-mysql${count.index}"
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_interface" "mysql" {
  count                     = var.azure_nexus
  name                      = "${var.project_name}-mysql${count.index}-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "${var.project_name}-mysql${count.index}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.priv_ip_mysql[count.index]
    public_ip_address_id          = element(azurerm_public_ip.mysql.*.id, count.index)
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine" "mysql" {
  count                 = var.azure_nexus
  name                  = "${var.project_name}-mysql${count.index}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.mysql.*.id, count.index)]
  vm_size               = var.azure_vmsize_mysql
  
  lifecycle {
    prevent_destroy = false
  }
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true
  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.azure_vmpublisher
    offer     = var.azure_vmoffer
    sku       = var.azure_vmsku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.project_name}-mysql${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = "100"
  }
  os_profile {
    computer_name  = "${var.project_name}-mysql${count.index}"
    admin_username = var.username
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = var.ssh_file
      key_data = var.key
    }
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_managed_disk" "mysql" {
  count                = var.azure_nexus
  name                 = "${var.project_name}-mysql${count.index}-disk1"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = var.azure_disktype_mysql
  create_option        = "Empty"
  disk_size_gb         = var.azure_diskgb_mysql
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "mysql" {
  count              = var.azure_nexus
  managed_disk_id    = element(azurerm_managed_disk.mysql.*.id, count.index)
  virtual_machine_id = element(azurerm_virtual_machine.mysql.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

########## nifi ############### 

resource "azurerm_public_ip" "nifi" {
  count               = var.azure_nifi
  name                = "${var.project_name}-nifi${count.index}-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.azure_public_ip_type
  domain_name_label   = "${var.project_name}-nifi${count.index}"
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_network_interface" "nifi" {
  count                     = var.azure_nifi
  name                      = "${var.project_name}-nifi${count.index}-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "${var.project_name}-nifi${count.index}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.priv_ip_nifi[count.index]
    public_ip_address_id          = element(azurerm_public_ip.nifi.*.id, count.index)
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine" "nifi" {
  count                 = var.azure_nifi
  name                  = "${var.project_name}-nifi${count.index}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.nifi.*.id, count.index)]
  vm_size               = var.azure_vmsize_nifi
  
  lifecycle {
    prevent_destroy = false
  }
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true
  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.azure_vmpublisher
    offer     = var.azure_vmoffer
    sku       = var.azure_vmsku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.project_name}-nifi${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = "100"
  }
  os_profile {
    computer_name  = "${var.project_name}-nifi${count.index}"
    admin_username = var.username
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = var.ssh_file
      key_data = var.key
    }
  }
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_managed_disk" "nifi" {
  count                = var.azure_nifi
  name                 = "${var.project_name}-nifi${count.index}-disk1"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = var.azure_disktype_nifi
  create_option        = "Empty"
  disk_size_gb         = var.azure_diskgb_nifi
  tags = {
    Environment = var.environment
    Invoice     = var.azure_invoice
    Project     = var.project_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "nifi" {
  count              = var.azure_nifi
  managed_disk_id    = element(azurerm_managed_disk.nifi.*.id, count.index)
  virtual_machine_id = element(azurerm_virtual_machine.nifi.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

# ######################### BACKUP #############################
# resource "azurerm_recovery_services_vault" "vault" {
#     name    = "${var.project_name}-vault"
#     location = "${azurerm_resource_group.main.location}"
#     resource_group_name = "${azurerm_resource_group.main.name}"
#     sku     = "Standard"
#     tags = {
#       Environment = "${var.environment}"
#       Invoice = "${var.azure_invoice}"
#       Project = "${var.project_name}"
#     }
# }
# resource "azurerm_recovery_services_protection_policy_vm" "pol" {
#   name                = "${var.project_name}-bkpol"
#   resource_group_name = "${azurerm_resource_group.main.name}"
#   recovery_vault_name = "${azurerm_recovery_services_vault.vault.name}"
#   timezone = "${var.timezonebk}"
#   backup = {
#     frequency = "Daily"
#     time      = "${var.timebk}"
#   }
#   retention_daily = {
#     count = "${var.countday}"
#   }
#   retention_weekly = {
#     count    = "${var.countweek}"
#     weekdays = ["Sunday"]
#   }
#   retention_monthly = {
#     count    = "${var.countmonth}"
#     weekdays = ["Saturday"]
#     weeks    = ["First"]
#   }
#   # retention_yearly = {
#   #   count    = "${var.countyear}"
#   #   weekdays = ["Sunday"]
#   #   weeks    = ["First"]
#   #   months   = ["January"]
#   # }
# }
# ### Backup pgsql ###
# resource "azurerm_recovery_services_protected_vm" "pgsql" {
#   resource_group_name = "${azurerm_resource_group.main.name}"
#   recovery_vault_name = "${azurerm_recovery_services_vault.vault.name}"
#   source_vm_id        = "${azurerm_virtual_machine.pgsql.id}"
#   backup_policy_id    = "${azurerm_recovery_services_protection_policy_vm.pol.id}"
# }
# ## Backup NFS ###
# resource "azurerm_recovery_services_protected_vm" "nfs" {
#   resource_group_name = "${azurerm_resource_group.main.name}"
#   recovery_vault_name = "${azurerm_recovery_services_vault.vault.name}"
#   source_vm_id        = "${azurerm_virtual_machine.nfs.id}"
#   backup_policy_id    = "${azurerm_recovery_services_protection_policy_vm.pol.id}"
# }