terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Le Modèle de base (Téléchargé 1 seule fois)
resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-jammy.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Les 3 disques durs indépendants (Basés sur le modèle, 10 Go chacun)
resource "libvirt_volume" "proxy_disk" {
  name           = "proxy-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_image.id
  size           = 10737418240
}

resource "libvirt_volume" "app_disk" {
  name           = "app-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_image.id
  size           = 10737418240
}

resource "libvirt_volume" "db_disk" {
  name           = "db-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_image.id
  size           = 10737418240
}

# 3. La configuration Cloud-Init (Ta clé SSH)
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default"
  user_data = <<-EOF
    #cloud-config
    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: users, admin
        ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfhmuX9xQGKiW3AFEo4DoPxBETOucKGaHYmbUcFI7c1
    EOF
}

# -------------------------------------------------------------------------
# MACHINE 1 : REVERSE PROXY NGINX
# -------------------------------------------------------------------------
resource "libvirt_domain" "proxy" {
  name   = "proxy-nginx"
  memory = "512"
  vcpu   = 1

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.proxy_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# -------------------------------------------------------------------------
# MACHINE 2 : APPLICATION WEB (FLASK)
# -------------------------------------------------------------------------
resource "libvirt_domain" "app" {
  name   = "app-flask"
  memory = "512"
  vcpu   = 1

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.app_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# -------------------------------------------------------------------------
# MACHINE 3 : BASE DE DONNÉES (POSTGRESQL)
# -------------------------------------------------------------------------
resource "libvirt_domain" "db" {
  name   = "db-postgres"
  memory = "512"
  vcpu   = 1

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.db_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# -------------------------------------------------------------------------
# AFFICHAGE DES ADRESSES IP
# -------------------------------------------------------------------------
output "proxy_ip" {
  value = libvirt_domain.proxy.network_interface[0].addresses[0]
}

output "app_ip" {
  value = libvirt_domain.app.network_interface[0].addresses[0]
}

output "db_ip" {
  value = libvirt_domain.db.network_interface[0].addresses[0]
}