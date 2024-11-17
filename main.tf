data "ibm_resource_group" "group" {
  name = "Test"
}

resource "ibm_is_vpc" "vpc" {
    name = "testify-vpc"
    resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_public_gateway" "pgw" {
  name = "public-gateway"
  vpc  = ibm_is_vpc.vpc.id
  zone = "jp-osa-1"
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "subnet" {
    name = "testify-subnet"
    vpc = ibm_is_vpc.vpc.id
    zone = "jp-osa-1"
    ipv4_cidr_block = "10.248.0.0/18"
    resource_group = data.ibm_resource_group.group.id
    public_gateway = ibm_is_public_gateway.pgw.id
}

resource "ibm_is_floating_ip" "public_ip_vm1" {
  name           = "testify-vm1-ip"
  target         = ibm_is_instance.vm_instance1.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.group.id
}

# resource "ibm_is_floating_ip" "public_ip_vm2" {
#   name           = "testify-vm2-ip"
#   target         = ibm_is_instance.vm_instance2.primary_network_interface[0].id
#   resource_group = data.ibm_resource_group.group.id
# }

resource "ibm_is_instance" "vm_instance1" {
  name    = "testify-vm1"
  image   = "r034-2aee2fde-574f-46a1-be77-e919b6847a9f"
  profile = "bx2-2x8"

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]
  }

  vpc    = ibm_is_vpc.vpc.id
  zone   = "jp-osa-1"
  keys   = [ibm_is_ssh_key.ssh_key.id]
  resource_group = data.ibm_resource_group.group.id
}

# resource "ibm_is_instance" "vm_instance2" {
#   name    = "testify-vm2"
#   image   = "r034-2aee2fde-574f-46a1-be77-e919b6847a9f"
#   profile = "bx2-2x8"

#   primary_network_interface {
#     subnet = ibm_is_subnet.subnet.id
#     security_groups = [ibm_is_security_group.sg.id]
#   }

#   vpc    = ibm_is_vpc.vpc.id
#   zone   = "jp-osa-1"
#   keys   = [ibm_is_ssh_key.ssh_key.id]
#   resource_group = data.ibm_resource_group.group.id
# }

# # Create database 
# resource "ibm_database" "postgresql_db" {
#   resource_group_id = data.ibm_resource_group.group.id
#   name              = "testify-db" 
#   service           = "databases-for-postgresql"
#   plan              = "standard"
#   location          = "jp-osa"
#   service_endpoints = "public"

#    users {
#     name     = "testify"
#     password = "testify1234testify"
#   }
#   group {
#     group_id = "member"
#     host_flavor {
#       id = "multitenant"
#     }
#     cpu {
#       allocation_count = 0
#     }
#     memory {
#       allocation_mb = 4096
#     }
#     disk {
#       allocation_mb = 5120
#     }
#   }
# }

resource "ibm_is_ssh_key" "ssh_key" {
  name       = "terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "sg" {
  name = "allow-ssh"
  vpc  = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "ssh_access" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  ip_version = "ipv4"
  remote     = "0.0.0.0/0"
  
}

resource "ibm_is_security_group_rule" "outbound_internet" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  ip_version = "ipv4"
  remote     = "0.0.0.0/0"
}

# Allow 80 443
resource "ibm_is_security_group_rule" "http_access" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  ip_version = "ipv4"
  remote     = "0.0.0.0/0"

}



output "vm1_public_ip" {
  description = "The public IP of VM instance 1"
  value       = ibm_is_floating_ip.public_ip_vm1.address
}

# output "vm2_public_ip" {
#   description = "The public IP of VM instance 2"
#   value       = ibm_is_floating_ip.public_ip_vm2.address
# }

# Output database service endpoint
# Output database service endpoint
# output "postgresql_service_endpoint" {
#   description = "The public endpoint for PostgreSQL database"
#   value       = ibm_database.postgresql_db.endpoints
# }

# Data source to fetch PostgreSQL database credentials



# connect to the instance using the floating IP and Run init.sh

# resource "null_resource" "init" {
#   provisioner "remote-exec" {
#     connection {
#       type        = "ssh"
#       user        = "root"
#       private_key = file("~/.ssh/id_rsa")
#       host        = ibm_is_floating_ip.public_ip.address
#     }

#     script = "init.sh"
#   }

#   depends_on = [ibm_is_floating_ip.public_ip]
# }
