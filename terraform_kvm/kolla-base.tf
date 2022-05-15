variable "nombre"    { default = "kolla-deb" }
variable "user_name" { default = "vmadmin" }
variable "user_pass" { default = "Test123456" }

module "cloud_init_disk" {
  source = "/home/repo/tf_modules/cloud_init"

  nombre = var.nombre

  search_domain         = ".ingress.lab.home"
  user_name             = var.user_name
  user_default_password = var.user_pass

}

module "node" {
  source = "/home/repo/tf_modules/kvm_complex_instance"

  depends_on= [
    module.cloud_init_disk
  ]

  # -- # Para crear multiples instancias
  # count = 2
  # nombre = "${var.nombre}-node-${count.index}"

  # -- # Para crear una instancia
  nombre = var.nombre

  cloud_init_data = module.cloud_init_disk.out_rendered
  # cloud_init_data = ""


  assigned_cpu = 6
  assigned_memory_mb  = 16384
  # os_base_path = "/home/repo/images/cirros-0.5.2-x86_64-disk.img"
  # os_base_path = "/home/repo/images/focal-server-cloudimg-amd64.img"
  os_base_path = "/home/repo/images/debian-11-generic-amd64-20211011-792.qcow2"
  # os_base_path = "/home/repo/images/debian-11-genericcloud-amd64-20211011-792.qcow2"
  # os_base_path = "/home/repo/images/debian-10-generic-amd64-20211011-792.qcow2"
  # os_base_path = "/home/repo/images/debian-10-genericcloud-amd64-20211011-792.qcow2"
  # os_base_path = "/home/repo/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2"

  # disk_list             = { "docker" : 1024, "data" : 512 }
  # network_name_list     = ["default", "default"]
  # network_name_list = ["default", "default"]
  network_name_list = ["default","default"]
  network_wait_dhcp_lease = true
  
  os_disk_size_mb = 20*1024
}




output "name" {
  value = module.node.*.name
}
output "ipv4_addressess" {
  value = module.node.*.ipv4_addressess
}
output "clean_out" {
  value = module.node.*.clean_out
}

###- ##Creacion de inventario para kubespray
resource "local_file" "inventory_ansible" {
  depends_on= [
    module.node
  ]
  content = templatefile("../templates/inventory.tmpl",
    {
      host_list  = module.node.*.clean_out
      hosts_user = var.user_name
    }
  )
  filename = "../tmp/hosts.yml"
}

output "ssh_conn" {
  value = <<EOT
ssh -o StrictHostKeyChecking=no vmadmin@${module.node.ipv4_addressess[0]}
ssh -o StrictHostKeyChecking=no vmadmin@192.168.122.254 cat kolla-venv/share/kolla-ansible/etc_examples/kolla/globals.yml > ../tmp/globals_default.yml
EOT
}


resource "null_resource" "excute_ansible" {
  depends_on = [
    # resource.libvirt_domain.complex_node_kvm_v1,
    resource.local_file.inventory_ansible
  ]
  provisioner "local-exec" {
    # command = "ansible-playbook ../ansible/playbook.yml -i ../tmp/hosts.yml"
    # command = "ANSIBLE_FORCE_COLOR=1 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml"
    command = "ANSIBLE_FORCE_COLOR=1 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ../ansible/playbook.yml -i ../tmp/hosts.yml"
  }
}
