module "cloud_init_disk" {
  # source = "/home/repo/tf_modules/cloud_init"
  source = "git::https://github.com/maxrinal/tf_modules.git//cloud_init"

  nombre = var.nombre

  search_domain         = ".ingress.lab.home"
  user_name             = var.user_name
  user_default_password = var.user_pass

}

module "node" {
  # source = "/home/repo/tf_modules/kvm_complex_instance"
  source = "git::https://github.com/maxrinal/tf_modules.git//kvm_complex_instance"

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


  assigned_cpu        = var.cpu
  assigned_memory_mb  = var.memory_mb
  os_base_path        = var.os_path

  # disk_list             = { "docker" : 1024, "data" : 512 }
  # network_name_list     = ["default", "default"]
  # network_name_list = ["default", "default"]
  network_name_list = ["default","default"]
  network_wait_dhcp_lease = true
  
  # os_disk_size_mb = 20*1024
  os_disk_size_mb = var.root_disk_size_mb
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
      ansible_extra_vars = var.ansible_extra_vars
    }
  )
  filename = "../tmp/hosts.yml"
}

output "ssh_conn" {
  value = <<EOT
ssh -o StrictHostKeyChecking=no vmadmin@${module.node.ipv4_addressess[0]}
ssh -o StrictHostKeyChecking=no vmadmin@${module.node.ipv4_addressess[0]} cat kolla-venv/share/kolla-ansible/etc_examples/kolla/globals.yml > ../tmp/globals_default.yml
EOT
}


resource "null_resource" "execute_ansible" {
  count  = ( var.EXECUTE_ANSIBLE == true ? 1:0)

  depends_on = [
    resource.local_file.inventory_ansible
  ]
  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ../ansible/playbook.yml -i ../tmp/hosts.yml"
  }
}
