data "ibm_resource_group" "group" {
  name = "Test"
}

resource "ibm_is_vpc" "vpc" {
    name = "test-vpc"
    resource_group = data.ibm_resource_group.group.id

}

resource "ibm_is_subnet" "subnet" {
    name = "test-subnet"
    vpc = ibm_is_vpc.vpc.id
    zone = "jp-osa-1"
    ipv4_cidr_block = "10.248.0.0/18"
    resource_group = data.ibm_resource_group.group.id

  
}

resource "ibm_is_floating_ip" "public_ip" {
  name           = "test-vm-ip"
  target         = ibm_is_instance.vm_instance.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_instance" "vm_instance" {
  name    = "test-vm"
  image   = "r034-32af8cbf-f7c7-438f-8b0e-e8ecbdba0b00"
  profile = "bx2-2x8"

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]  # Assuming a security group is defined to allow SSH
  }

  vpc    = ibm_is_vpc.vpc.id
  zone   = "jp-osa-1"
  keys   = [ibm_is_ssh_key.ssh_key.id]
  resource_group = data.ibm_resource_group.group.id




}


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


# connect to the instance using the floating IP and Run init.sh

resource "null_resource" "init" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = ibm_is_floating_ip.public_ip.address
    }

    script = "init.sh"
  }

  depends_on = [ibm_is_floating_ip.public_ip]
}
