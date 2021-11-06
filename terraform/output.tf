# Armo un array cuya clave es el nombre de la vm y su valor es la ip de cada una
output "ip_vms" {
 value = zipmap( "${libvirt_domain.rs-domain-kvm-vms.*.name}", "${libvirt_domain.rs-domain-kvm-vms.*.network_interface.0.addresses.0}")
}

# Armo un array cuya clave es el nombre de la vm y su valor es el path del disco
output "disk_path" {
    value = zipmap( "${libvirt_domain.rs-domain-kvm-vms.*.name}", "${libvirt_domain.rs-domain-kvm-vms.*.disk.0.volume_id}")
}


# content = templatefile("./templates/inventory.tmpl",
# Creacion de inventario para kubespray
resource "local_file" "inventory_k3s" {
  content = templatefile("./templates/inventory.tmpl",
    {
      hosts_ipv4 = resource.libvirt_domain.rs-domain-kvm-vms.*.network_interface.0.addresses.0
      hosts_name = resource.libvirt_domain.rs-domain-kvm-vms.*.name
    }
  )
  filename = "inventory/sample/hosts.ini"
}