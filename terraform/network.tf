
resource "libvirt_network" "kube_network" {
  # the name used by libvirt
  name = var.network_name

  # mode can be: "nat" (default), "none", "route", "bridge"
  mode = "nat"

  #  the domain used by the DNS server in this network
  domain = var.search_domain


  autostart = true

  #  list of subnets the addresses allowed for domains connected
  # also derived to define the host addresses
  # also derived to define the addresses served by the DHCP server

  #   addresses = ["192.168.123.0/24", "2001:db8:ca2:2::1/64"]
  addresses = ["${var.network_prefix}.0/24"]

  # (optional) the bridge device defines the name of a bridge device
  # which will be used to construct the virtual network.
  # (only necessary in "bridge" mode)
  # bridge = "br7"

  # (optional) the MTU for the network. If not supplied, the underlying device's
  # default is used (usually 1500)
  # mtu = 9000

  # (Optional) DNS configuration
  dns {
    # (Optional, default false)
    # Set to true, if no other option is specified and you still want to 
    # enable dns.
    enabled = true
    # (Optional, default false)
    # true: DNS requests under this domain will only be resolved by the
    # virtual network's own DNS server
    # false: Unresolved requests will be forwarded to the host's
    # upstream DNS server if the virtual network's DNS server does not
    # have an answer.
    local_only = true

    # (Optional) one or more DNS forwarder entries.  One or both of
    # "address" and "domain" must be specified.  The format is:
    # forwarders {
    #     address = "my address"
    #     domain = "my domain"
    #  } 
    # 

    # (Optional) one or more DNS host entries.  Both of
    # "ip" and "hostname" must be specified.  The format is:
    # hosts  {
    #     hostname = "my_hostname"
    #     ip = "my.ip.address.1"
    #   }
    # hosts {
    #     hostname = "my_hostname"
    #     ip = "my.ip.address.2"
    #   }
    #

    # Creo un bloque dinamico para repetir el bloque hosts, ya que la definicion de template_hosts no funciona
    # SOURCE: https://jhooq.com/terraform-dynamic-block/
    dynamic "hosts" {
      for_each = var.load_balancer_domain_list
      content {
        ip = "${var.network_prefix}.${var.load_balancer_ip}"
        hostname =  "${hosts.value}.${var.search_domain}" 
      }
    }

    # (Optional) one or more static routes.
    # "cidr" and "gateway" must be specified. The format is:
    # routes {
    #     cidr = "10.17.0.0/16"
    #     gateway = "10.18.0.2"
    #   }
  }

  # (Optional) Dnsmasq options configuration
  dnsmasq_options {
    # (Optional) one or more option entries.  Both of
    # "option_name" and "option_value" must be specified.  The format is:
    options  {
        option_name = "server"
        option_value = "/${var.search_domain}/${var.network_prefix}.1"
      }
    # options {
    #     option_name = "address"
    #     ip = "/.api.base.domain/my.ip.address.2"
    #   }
    #
  }

}