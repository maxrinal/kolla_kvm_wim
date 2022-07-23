variable "nombre"    { default = "kolla-deb" }
variable "user_name" { default = "vmadmin" }
variable "user_pass" { default = "Test123456" }
variable "os_path"   { default = "/home/repo/images/debian-11-generic-amd64-20211011-792.qcow2" }
variable "cpu"       { default = 6 }
variable "memory_mb" { default = 16384 }
variable "root_disk_size_mb" { default = 20*1024 }

# Auto execute ansible k3s-deploy
variable "EXECUTE_ANSIBLE" {default = false}

variable "ansible_extra_vars" {
  default = <<EOF
EOF
  type    = string
}