

```bash
export ENABLE_EXT_NET=1
export EXT_NET_CIDR=192.168.122.0/24
export EXT_NET_RANGE='start=192.168.122.50,end=192.168.122.100'
export EXT_NET_GATEWAY='192.168.122.1'
export KOLLA_OPENSTACK_COMMAND='openstack'


# This EXT_NET_CIDR is your public network,that you want to connect to the internet via.
# ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
# EXT_NET_CIDR=${EXT_NET_CIDR:-'10.0.2.0/24'}
# EXT_NET_RANGE=${EXT_NET_RANGE:-'start=10.0.2.150,end=10.0.2.199'}
# EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'10.0.2.1'}

echo $ENABLE_EXT_NET $EXT_NET_CIDR $EXT_NET_RANGE $EXT_NET_GATEWAY 

if [[ $ENABLE_EXT_NET -eq 1 ]]; then
    $KOLLA_OPENSTACK_COMMAND network create --external --provider-physical-network physnet1 \
        --provider-network-type flat public1
    # $KOLLA_OPENSTACK_COMMAND subnet create --no-dhcp \
    $KOLLA_OPENSTACK_COMMAND subnet create --dhcp \
        --allocation-pool ${EXT_NET_RANGE} --network public1 \
        --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet
    # $KOLLA_OPENSTACK_COMMAND router set --external-gateway public1 demo-router
fi


openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --network demo-net \
    --security-group full \
    demo1


openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --network public1 \
    --security-group full \
    demo2-public

ssh cirros@192.168.122.100




openstack router show | grep ip_addres

| external_gateway_info   | {"network_id": "d1376577-4499-430e-adcf-351869200ddd", "external_fixed_ips": [{"subnet_id": "a81b595b-4be3-4b57-be8a-b233ad292565", "ip_address": "192.168.122.68"}], "enable_snat": true} |
| interfaces_info         | [{"port_id": "5b30c2e9-2913-43fe-b197-c5e83894e46b", "ip_address": "10.0.0.1", "subnet_id": "d93587d5-1788-4a0a-8cdc-eeb6c6178412"}]    


# Agregamos ruta estatica ingresando por la ip del router
ip route add 10.0.0.0/24 via 192.168.122.68 

ssh cirros@10.0.0.244


``` 