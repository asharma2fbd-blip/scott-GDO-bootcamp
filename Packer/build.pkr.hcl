packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "amazon-ebs" "bootcamp_ami" {
  ami_name      = "gdo-bootcamp-golden-image-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
  tags = {
    Name    = "GDO-Bootcamp-Golden-AMI"
    Project = "GDO-Bootcamp"
    Task    = "5"
  }
}

build {
  name    = "gdo-build"
  sources = [
    "source.amazon-ebs.bootcamp_ami"
  ]

  # 1. Install Ansible directly on the temporary build instance using pip
  provisioner "shell" {
    inline = [
      "sudo dnf install python3-pip -y",
      "sudo pip3 install ansible"
    ]
  }

  # 2. Use your existing Ansible playbook to bake the image
  provisioner "ansible-local" {
    playbook_file = "../Ansible/playbook.yml"
  }
}
