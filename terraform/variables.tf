variable "network_name" {}
variable "network_prefix" {}
variable "search_domain" {}
variable "load_balancer_ip" {}
variable "load_balancer_domain_list" {}

#User options
variable "user_name" {}
variable "user_default_password" {}

#Computer configurations
variable "nombres" {}
variable "ips" {}
variable "macs" {}
variable "lista_cpu" {}
variable "lista_ram" {}


# Originally this disk is 2gb, but I can grow it 
# https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-disk-kvm.img
# After download you must rename and resie the disk "qemu-img resize ubuntu20.qcow2 +8G"
variable "os_base_path" {}

