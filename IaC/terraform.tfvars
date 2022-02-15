### Azure (FIXED)
azure_subs   = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
azure_tenant = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

### Virtual Machine (FIXED)
azure_vmsku       = "20_04-lts"
azure_vmpublisher = "canonical"
azure_vmoffer     = "0001-com-ubuntu-server-focal"
username          = "ansible"
ssh_file          = "/home/ansible/.ssh/authorized_keys"
key               = "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

### Virtual Machine Windows (FIXED)
azurew_vmsku       = "2019-datacenter-with-containers-g2"
azurew_vmpublisher = "MicrosoftWindowsServer"
azurew_vmoffer     = "WindowsServer"
usernamew          = "devops"

### Project (VAR)
azure_location = "eastasia"
project_name   = "wsd"
azure_invoice  = "PROY23"
environment    = "PRO"

azure_app                  = 1
azure_nexus                = 1
azure_nifi                 = 1
azure_nfs                  = 1
azure_replicas_swarm       = 3

##Security (VAR)
allowed_ips = [
  "XXXXXXXXXX"
]
allowed_ipswaf = [
  "XXXXXXXXXXX"
]

allowed_ipsnifi = [
  "XXXXXXXXX"
]

#### Change Public IP type to STATIC in PRO Environments ######

azure_public_ip_type = "Static"

##### Change DISK type to "Premium_LRS" in PRO Environments #######

### VM Swarm (VAR)

azure_vmsize_swarm   = "Standard_B4ms"
azure_disktype_swarm = "StandardSSD_LRS"
azure_diskgb_swarm   = "50"
priv_ip_swarm = [
  "10.0.5.211",
  "10.0.5.212",
  "10.0.5.213",
  "10.0.5.214",
  "10.0.5.215",
  "10.0.5.216",
  "10.0.5.217",
  "10.0.5.218",
  "10.0.5.219"
]

### VM NFS (VAR)
azure_vmsize_nfs   = "Standard_B2s"
azure_disktype_nfs = "StandardSSD_LRS"
azure_diskgb_nfs   = "21"
priv_ip_nfs        = ["10.0.5.202"]

### VM pgsql (VAR)
azure_vmsize_pgsql   = "Standard_D2s_v3"
azure_disktype_pgsql = "StandardSSD_LRS"
azure_diskgb_pgsql   = "22"
priv_ip_pgsql        = ["10.0.5.201"]

### VM Nexus (VAR)
azure_vmsize_nex   = "Standard_B4MS"
azure_disktype_nex = "StandardSSD_LRS"
priv_ip_nex        = ["10.0.5.205"]

### VM mysql (VAR)
azure_vmsize_mysql   = "Standard_D2s_v3"
azure_disktype_mysql = "StandardSSD_LRS"
azure_diskgb_mysql   = "23"
priv_ip_mysql        = ["10.0.5.204"]

### VM NIFI (VAR) 
azure_vmsize_nifi   = "Standard_B2s"
azure_disktype_nifi = "StandardSSD_LRS"
azure_diskgb_nifi   = "24"
priv_ip_nifi        = [
   "10.0.5.231",   
   "10.0.5.232",
   "10.0.5.233",   
   "10.0.5.234",
   "10.0.5.235",   
   "10.0.5.236"
]

## BACKUP (VAR)
timezonebk = "Hong Kong Time"
timebk     = "03:00"
countday   = "7"
countweek  = "2"
countmonth = "2"
countyear  = "1"