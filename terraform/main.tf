# Creo el disco para cada una de las vms
resource "libvirt_volume" "rs-vol-vms-k3s-qcow2" {
  count  = length(var.nombres)
  name   = "${var.nombres[count.index]}.qcow2"
  source = var.os_base_path
  format = "qcow2"
}

# Creo el cloudinit disk para cada una de las vms
resource "libvirt_cloudinit_disk" "rs_ci_disk" { 
  count     = length(var.nombres)
  name      = "commoninit-${var.nombres[count.index]}.iso"
  user_data = templatefile("${path.module}/templates/user_data.tpl", {
      host_name     = var.nombres[count.index]
      search_domain = var.search_domain

      auth_key  = file("${path.module}/ssh/id_rsa.pub")

      user_name = var.user_name
      user_default_password = var.user_default_password
  })

}


# Creo las vms necesarias
resource "libvirt_domain" "rs-domain-kvm-vms" {
  
  count  = length(var.nombres)
  name   = var.nombres[count.index]
  memory = var.lista_ram[count.index]
  vcpu   = var.lista_cpu[count.index]
  
  
  # Asigno el disco base de SO
  disk {
    volume_id = element(libvirt_volume.rs-vol-vms-k3s-qcow2.*.id, count.index)
  }

  # Asigno el disco/iso cloudinit, que permite inicializar el sistema operativo
  cloudinit = element(libvirt_cloudinit_disk.rs_ci_disk.*.id, count.index)

  network_interface {
    network_name = var.network_name
    hostname     = var.nombres[count.index]
    
    addresses = [ "${var.network_prefix}.${var.ips[count.index]}" ]
    mac = var.macs[count.index]
    # Espero que me de la ip para luego poder obtenerla
    wait_for_lease = true
  }

  console {
    type = "pty" 
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }


}

# resource "null_resource" "excute_ansible_k3s" {
#   depends_on = [
#     resource.libvirt_domain.rs-domain-kvm-vms,
#     resource.local_file.inventory_k3s
#   ]
#   provisioner "local-exec" {
#     command = "cd ../ansible/ && ansible-playbook site.yml -i inventory/sample/hosts.ini"
#   }
# }

# resource "null_resource" "excute_manifest" {
#   depends_on = [
#     resource.null_resource.excute_ansible_k3s
#   ]
#   provisioner "local-exec" {
#     command = "cd ../k3s-03-addons/ && ssh -o StrictHostKeyChecking=no vmadmin@192.168.123.11 sudo kubectl config view --raw | sed 's/127.0.0.1/192.168.123.11/g' >  kubeconfig"
#   }
# }