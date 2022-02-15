### Project Common
variable "azure_subs" {
}

variable "azure_tenant" {
}

variable "azure_location" {
}

variable "project_name" {
}

variable "azure_invoice" {
}

variable "environment" {
}

variable "azure_goaigua" {
}

variable "azure_nexus" {
}

variable "azure_nifi" {
}
variable "azure_nfs" {
}

### Linux VM
variable "azure_vmoffer" {
}

variable "azure_vmsku" {
}

variable "azure_vmpublisher" {
}

variable "username" {
}

variable "key" {
}

variable "ssh_file" {
}

### Windows VM ###
variable "azurew_vmoffer" {
}

variable "azurew_vmsku" {
}

variable "azurew_vmpublisher" {
}

variable "usernamew" {
}

##variable "adminpwdw" {}  

## Security

variable "allowed_ips" {
  type = list(string)
}

variable "allowed_ipswaf" {
  type = list(string)
}

variable "allowed_ipsnifi" {
  type = list(string)
}

### Public IP Type
variable "azure_public_ip_type" {
}

### VM Swarm ###
variable "azure_replicas_swarm" {
}

variable "azure_vmsize_swarm" {
}

variable "azure_disktype_swarm" {
}

variable "azure_diskgb_swarm" {
}

variable "priv_ip_swarm" {
  type = list(string)
}

### VM NFS ###
variable "azure_vmsize_nfs" {
}

variable "azure_diskgb_nfs" {
}

variable "azure_disktype_nfs" {
}

variable "priv_ip_nfs" {
}

### VM pgsql PostgreSQL ###
variable "azure_vmsize_pgsql" {
}

variable "azure_diskgb_pgsql" {
}

variable "azure_disktype_pgsql" {
}

variable "priv_ip_pgsql" {
}

### VM NIFI ###
variable "azure_vmsize_nifi" {
}

variable "azure_diskgb_nifi" {
}

variable "azure_disktype_nifi" {
}

variable "priv_ip_nifi" {
  type = list(string)
}

### VM Mysql Nexus ###
variable "azure_vmsize_mysql" {
}

variable "azure_diskgb_mysql" {
}

variable "azure_disktype_mysql" {
}

variable "priv_ip_mysql" {
}

### VM Nexus ###
variable "azure_vmsize_nex" {
}

variable "azure_disktype_nex" {
}

variable "priv_ip_nex" {
}
variable "adminpwdw" {
  
}

### Backup ###
variable "timezonebk" {
}

variable "timebk" {
}

variable "countday" {
}

variable "countweek" {
}

variable "countmonth" {
}

variable "countyear" {
}

