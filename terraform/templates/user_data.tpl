#cloud-config
# vim: syntax=yaml
timezone: "America/Argentina/Buenos_Aires"
hostname: ${host_name}
fqdn: "${host_name}.${search_domain}"
manage_etc_hosts: true
enable_dns: true
users:
  - name: ${user_name}
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${auth_key}
    ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:${user_default_password}
    ${user_name}:${user_default_password}
  expire: false
growpart:
  mode: auto
  devices: ['/']
# runcmd:
#    - timedatectl set-timezone America/Argentina/Buenos_Aires
# https://cloudinit.readthedocs.io/en/latest/topics/modules.html
