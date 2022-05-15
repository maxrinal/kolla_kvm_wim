# KOLLA-ANSIBLE OVER KVM

Creamos la vm via terraform, desplegamos inventario inicial con ansible e instalamos precondiciones para kolla

```bash
cd terraform_kvm


terraform init
terraform plan -out="plan"
terraform apply plan

#instead of plan 
terraform apply -auto-approve
```

Para borrar el despligue
```bash
# terraform destroy -auto-approve
```

pingear los host previo a la ejecucion de ansible

```bash
#BINARY -m ${MODULE_NAME}  -i ${INVENTORY_FILE} ${PATTERN}
# Validmos el ping(corectas credencials)
ansible -m ping -i ../tmp/hosts.yml all
# Validmos ejecucion de comandos usando shell
ansible -m shell -i ../tmp/hosts.yml all -a "hostname"

# Deshabilitamos la placa secundaria
cat <<EOT | sudo tee /etc/network/interfaces.d/51-ens4
auto ens4
allow-hotplug ens4

iface ens4 inet manual

# ip addr flush dev ens4
# ip addr flush dev br-ex

# ip link set ens4 down
# ip link set ens4 up
EOT

```


# INICIAMOS PROCESO


```bash
screen 
cd /etc/kolla

source ~/kolla-venv/bin/activate


# Se debe hacer downgrade de jinja2 por cuestion de compatiblidad(ya resuelto en playbook)
# Bug ansible https://bugs.launchpad.net/kolla-ansible/+bug/1966606
# downgrade jinja2=3.0.3

# Bootstrapeamos
kolla-ansible -i all-in-one bootstrap-servers


# borramos todo del archivo /etc/hosts

# ejecutamos pre checks
kolla-ansible -i all-in-one prechecks


# Valido el pull de imagenes
kolla-ansible -i all-in-one pull


# Ejecuto el deploy
kolla-ansible -i all-in-one deploy

# kolla-ansible -i all-in-one reconfigure



# Generate an openrc file with administrator user credentials set

kolla-ansible post-deploy

cat /etc/kolla/admin-openrc.sh



# Destroy cluster
# kolla-ansible -i all-in-one destroy --yes-i-really-really-mean-it
# sudo rm -Rf /etc/kolla


```


# Basic conf for openstack


In regards to networking, edit the init-runonce script and configure your public network,that you want to connect to the internet via.

```bash
cd ~
source ~/kolla-venv/bin/activate
source /etc/kolla/admin-openrc.sh


# echo "set mouse-=a" | tee -a  ~/.vimrc
# echo "syntax on" | tee -a  ~/.vimrc
# vim ~/kolla-venv/share/kolla-ansible/init-runonce



# This EXT_NET_CIDR is your public network,that you want to connect to the internet via.
export ENABLE_EXT_NET=1
export EXT_NET_CIDR=192.168.122.0/24
export EXT_NET_RANGE='start=192.168.122.50,end=192.168.122.100'
export EXT_NET_GATEWAY='192.168.122.1'


# This EXT_NET_CIDR is your public network,that you want to connect to the internet via.
# ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
# EXT_NET_CIDR=${EXT_NET_CIDR:-'10.0.2.0/24'}
# EXT_NET_RANGE=${EXT_NET_RANGE:-'start=10.0.2.150,end=10.0.2.199'}
# EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'10.0.2.1'}

echo $ENABLE_EXT_NET $EXT_NET_CIDR $EXT_NET_RANGE $EXT_NET_GATEWAY 

sed -i 's/no-dhcp/dhcp/g' ~/kolla-venv/share/kolla-ansible/init-runonce
~/kolla-venv/share/kolla-ansible/init-runonce


To deploy a demo instance, run:

openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --network demo-net \
    demo1

openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --network public1 \
    demo2-public



```
















<!-- 








# INICIAMOS PROCESO


```bash
screen 
source ~/kolla-venv/bin/activate

# Ya realizado con el playbook
# cd /etc/kolla
# kolla-genpwd
# sed -i 's/^keystone_admin_password: .*/keystone_admin_password: kolla/g' passwords.yml

# Vaidamos que la clave de keystone este ok
# cat passwords.yml  | grep ^keystone_admin_password
```




# Configuramos global.yml

```yaml
cat <<EOF > globals.yml
kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
# openstack_release: "victoria"
openstack_release: "wallaby"
# Valid options are [ qemu, kvm, vmware ]
nova_compute_virt_type: "qemu"

##############################
# Neutron - Networking Options
##############################
# This interface is what all your api services will be bound to by default.
# Additionally, all vxlan/tunnel and storage network traffic will go over this
# interface by default. This interface must contain an IP address.
# It is possible for hosts to have non-matching names of interfaces - these can
# be set in an inventory file per host or per group or stored separately, see
#     http://docs.ansible.com/ansible/intro_inventory.html
# Yet another way to workaround the naming problem is to create a bond for the
# interface on all hosts and give the bond name here. Similar strategy can be
# followed for other types of interfaces.
#network_interface: "eth0"
network_interface: "ens3"

# This is the raw interface given to neutron as its external network port. Even
# though an IP address can exist on this interface, it will be unusable in most
# configurations. It is recommended this interface not be configured with any IP
# addresses for that reason.
neutron_external_interface: "ens4"


# enable_haproxy: "no"
# enable_keepalived: "no"
#enable_haproxy: "yes"
#enable_keepalived: "{{ enable_haproxy | bool }}"
enable_haproxy: "yes"
enable_keepalived: "yes"
# This should be a VIP, an unused IP on your network that will float between
# the hosts running keepalived for high-availability. If you want to run an
# All-In-One without haproxy and keepalived, you can set enable_haproxy to no
# in "OpenStack options" section, and set this value to the IP of your
# 'network_interface' as set in the Networking section below.
kolla_internal_vip_address: "192.168.122.240"


# Using harbor secure registry with project name(project name ~ namespace)
# docker_registry: 'harbor.k8s.maxrinal.test'
# docker_namespace: 'cachedhub/kolla'


# Using insecure registry(simple docker pull trough cache)
docker_registry: 192.168.122.1:4000
# Test docker_regsitry reachable 
# curl 192.168.122.1:4000/v2/_catalog
docker_registry_insecure: yes
docker_namespace: "kolla"



enable_horizon: yes

openstack_logging_debug: yes


enable_designate: "yes"
enable_barbican: "yes"

# enable_horizon_karbor: yes
# enable_murano: yes
# enable_horizon_magnum: "yes"
# enable_trove: "yes"


EOF
```




```
# Bug ansible https://bugs.launchpad.net/kolla-ansible/+bug/1966606
# downgrade jinja2=3.0.3

# Bootstrapeamos
kolla-ansible -i all-in-one bootstrap-servers


# borramos todo del archivo /etc/hosts

# ejecutamos pre checks
kolla-ansible -i all-in-one prechecks


# Valido el pull de imagenes
kolla-ansible -i all-in-one pull


# Ejecuto el deploy
kolla-ansible -i all-in-one deploy

# kolla-ansible -i all-in-one reconfigure



# Generate an openrc file with administrator user credentials set

kolla-ansible post-deploy

cat /etc/kolla/admin-openrc.sh



# Destroy cluster
# kolla-ansible -i all-in-one destroy --yes-i-really-really-mean-it
# sudo rm -Rf /etc/kolla


```


# Basic conf for openstack


In regards to networking, edit the init-runonce script and configure your public network,that you want to connect to the internet via.

vim /home/centos/kolla-venv/share/kolla-ansible/init-runonce
















# FULL IMAGE LIST 

```
REPOSITORY                                                         TAG       IMAGE ID       CREATED        SIZE
192.168.0.46:5000/kolla/ubuntu-binary-trove-api                    wallaby   537d2775048c   12 hours ago   550MB
192.168.0.46:5000/kolla/ubuntu-binary-placement-api                wallaby   636b3d738ef2   12 hours ago   535MB
192.168.0.46:5000/kolla/ubuntu-binary-trove-taskmanager            wallaby   48cfb18e0542   12 hours ago   549MB
192.168.0.46:5000/kolla/ubuntu-binary-trove-conductor              wallaby   c8743df8f4a7   12 hours ago   549MB
192.168.0.46:5000/kolla/ubuntu-binary-glance-api                   wallaby   ee8924442ea7   12 hours ago   606MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-compute                 wallaby   090494c98af6   12 hours ago   991MB
192.168.0.46:5000/kolla/ubuntu-binary-neutron-server               wallaby   c5b722f2010b   12 hours ago   595MB
192.168.0.46:5000/kolla/ubuntu-binary-neutron-metadata-agent       wallaby   71398f0d17ff   12 hours ago   592MB
192.168.0.46:5000/kolla/ubuntu-binary-neutron-l3-agent             wallaby   8f1be0dbc26e   12 hours ago   596MB
192.168.0.46:5000/kolla/ubuntu-binary-neutron-openvswitch-agent    wallaby   035f105b3e2e   12 hours ago   589MB
192.168.0.46:5000/kolla/ubuntu-binary-neutron-dhcp-agent           wallaby   f279ca206c09   12 hours ago   593MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-novncproxy              wallaby   9101924158f4   12 hours ago   674MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-conductor               wallaby   33dc785a3e54   12 hours ago   664MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-api                     wallaby   a7081b8ab071   12 hours ago   667MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-scheduler               wallaby   0c195ad30acd   12 hours ago   664MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-ssh                     wallaby   4d85b29ead99   12 hours ago   667MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-api                wallaby   f9b786f5ba3e   12 hours ago   502MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-worker             wallaby   380771c89a9d   12 hours ago   508MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-central            wallaby   1594531f46d7   12 hours ago   502MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-mdns               wallaby   7874b49e1ab9   12 hours ago   502MB
192.168.0.46:5000/kolla/ubuntu-binary-heat-engine                  wallaby   bf1f3844af51   12 hours ago   573MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-sink               wallaby   f809b5d102a6   12 hours ago   502MB
192.168.0.46:5000/kolla/ubuntu-binary-heat-api                     wallaby   1d0e10daa87d   12 hours ago   536MB
192.168.0.46:5000/kolla/ubuntu-binary-heat-api-cfn                 wallaby   dc1ba682316f   12 hours ago   536MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-producer           wallaby   3b4deb65139b   12 hours ago   502MB
192.168.0.46:5000/kolla/ubuntu-binary-horizon                      wallaby   1d69376eb5ee   12 hours ago   648MB
192.168.0.46:5000/kolla/ubuntu-binary-designate-backend-bind9      wallaby   5d93aae78612   12 hours ago   466MB
192.168.0.46:5000/kolla/ubuntu-binary-keystone-ssh                 wallaby   bbd5efa6574f   12 hours ago   518MB
192.168.0.46:5000/kolla/ubuntu-binary-keystone                     wallaby   9277f1f303a8   12 hours ago   511MB
192.168.0.46:5000/kolla/ubuntu-binary-keystone-fernet              wallaby   85910453dd88   12 hours ago   516MB
192.168.0.46:5000/kolla/ubuntu-binary-barbican-api                 wallaby   b078c29538a8   12 hours ago   496MB
192.168.0.46:5000/kolla/ubuntu-binary-barbican-worker              wallaby   8e22cbe86251   12 hours ago   491MB
192.168.0.46:5000/kolla/ubuntu-binary-barbican-keystone-listener   wallaby   a27eba3ccedf   12 hours ago   491MB
192.168.0.46:5000/kolla/ubuntu-binary-kolla-toolbox                wallaby   58271e365a66   12 hours ago   1.09GB
192.168.0.46:5000/kolla/ubuntu-binary-mariadb-server               wallaby   04a75b6eadd3   12 hours ago   602MB
192.168.0.46:5000/kolla/ubuntu-binary-nova-libvirt                 wallaby   495a1f24b59c   12 hours ago   985MB
192.168.0.46:5000/kolla/ubuntu-binary-mariadb-clustercheck         wallaby   fd0569dfaaa1   12 hours ago   288MB
192.168.0.46:5000/kolla/ubuntu-binary-openvswitch-db-server        wallaby   bdfe0dc94bdb   12 hours ago   272MB
192.168.0.46:5000/kolla/ubuntu-binary-openvswitch-vswitchd         wallaby   15b202fd1642   12 hours ago   272MB
192.168.0.46:5000/kolla/ubuntu-binary-cron                         wallaby   9f61d4373ed7   12 hours ago   255MB
192.168.0.46:5000/kolla/ubuntu-binary-fluentd                      wallaby   b9af90dd6572   12 hours ago   505MB
192.168.0.46:5000/kolla/ubuntu-binary-haproxy                      wallaby   6b3fd88ad97f   12 hours ago   261MB
192.168.0.46:5000/kolla/ubuntu-binary-keepalived                   wallaby   58ea0ad25acb   12 hours ago   272MB
192.168.0.46:5000/kolla/ubuntu-binary-rabbitmq                     wallaby   913a52b7e646   12 hours ago   302MB
192.168.0.46:5000/kolla/ubuntu-binary-memcached                    wallaby   ec365a654268   12 hours ago   255MB

``` -->