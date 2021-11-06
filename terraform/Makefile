


# Inicializa terraform en el directorio actual, descarga providers y mas
init:
	terraform init

# Muestra el plan de ejecucion
plan:
	terraform plan


# Valida que los procedimiento/archivos de configuracion sean correctos
validate:
	terraform validate

# Inenta ejecutar el plan
create:
	terraform apply -auto-approve
	

# Inenta ejecutar el plan pero destruyendo
destroy:
	terraform destroy -auto-approve

dhcp:
	virsh net-dhcp-leases --network default