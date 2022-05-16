# KOLLA-ANSIBLE OVER KVM

Kolla Kvm WIM nos permite desplegar openstack all in one basado en modulos personalizados de kvm y terraform


Obtencion de módulos
```bash 
# Por default asumimos que tenemos los modulos en el siguiente directorio, caso contrario debemos modificar el directorio en terraform
TF_MODULES_DEST_DIR=/home/repo/tf_modules
TF_MODULES_GIT_REPO=git@github.com:maxrinal/tf_modules.git

sudo mkdir -m 777 -p $TF_MODULES_DEST_DIR

git clone ${TF_MODULES_GIT_REPO} ${TF_MODULES_DEST_DIR} 

```


Creamos la vm via terraform, desplegamos inventario inicial con ansible e instalamos precondiciones para kolla

```bash
cd terraform_kvm


terraform init
terraform plan -out="plan"
terraform apply plan

#instead of plan 
terraform apply -auto-approve

# Para borrar el despligue
# terraform destroy -auto-approve
```

Pingear los host previo a la ejecucion de ansible

```bash
#BINARY -m ${MODULE_NAME}  -i ${INVENTORY_FILE} ${PATTERN}
# Validmos el ping(corectas credencials)
ansible -m ping -i ../tmp/hosts.yml all
# Validmos ejecucion de comandos usando shell
ansible -m shell -i ../tmp/hosts.yml all -a "hostname"

# Deshabilitamos la placa secundaria que sera utilizada como provider network
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

# Para conectarse a la instancia que está en la red demo-net  debemos utilizar una ruta personalizada, ingresando por la ip del router

openstack router show | grep ip_addres

| external_gateway_info   | {"network_id": "d1376577-4499-430e-adcf-351869200ddd", "external_fixed_ips": [{"subnet_id": "a81b595b-4be3-4b57-be8a-b233ad292565", "ip_address": "192.168.122.68"}], "enable_snat": true} |
| interfaces_info         | [{"port_id": "5b30c2e9-2913-43fe-b197-c5e83894e46b", "ip_address": "10.0.0.1", "subnet_id": "d93587d5-1788-4a0a-8cdc-eeb6c6178412"}]    


# Agregamos ruta estatica ingresando por la ip del router
ip route add 10.0.0.0/24 via 192.168.122.68 

ssh cirros@10.0.0.244


```







# EXTRA INFO

## DOCKER REGISTRY CACHE

Se asume disponible una docker-registry cache, para acelerar el despligue
```bash
# Creacion de volume
docker volume create cache-docker-reg

# Despligue docker-registry cache en puerto 4000 del host
docker run -d -p 4000:5000 \
    -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
    --volume cache-docker-reg:/var/lib/registry \
    --restart always \
    --name registry-docker.io registry:2

# Validacion de logs 
docker logs -f registry-docker.io

# Validacion de cache de imagenes descargadas

curl localhost:4000/v2/_catalog | jq 
```


## TERRAFORM PLUGIN CACHE DIR

Para ahorrar espacio en nuestro directorio podremos descargarlos de forma global generando un directorio para esa cache y configurandolo en un archivo **.terraformrc**, el mismo debe ser generado de forma manual caso contrario obtendremos un error.

```bash
mkdir -p $HOME/.terraform.d/plugin-cache
cat <<EOT | tee $HOME/.terraformrc
plugin_cache_dir   = "\$HOME/.terraform.d/plugin-cache"
EOT
```
