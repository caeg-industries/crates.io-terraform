data "aws_instance" "crates_server" {
  instance_id = aws_instance.bastion_host.id
}

resource "null_resource" "server_bootstrap" {
  depends_on = [data.aws_instance.crates_server]

  provisioner "remote-exec" {
    script = "scripts/bootstrap.sh"
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "file" {
    content     = "DATABASE_URL=postgres://${var.postgresql_username}:${random_string.password.result}@${aws_db_instance._.endpoint}/${aws_db_instance._.name}"
    destination = "crates.io/.env"
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "remote-exec" {
    script = "scripts/build.sh"
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }
}

resource "tls_private_key" "ssh_git_keys" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "server_configure_a" {
  depends_on = [
    null_resource.server_bootstrap]

  provisioner "remote-exec" {
    inline = [
      "mkdir -p .config/systemd/user",
      "mkdir -p .config/crates",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }
}

resource "null_resource" "server_configure_b" {
  depends_on = [null_resource.server_configure_a]

  provisioner "file" {
    content = templatefile("scripts/secure.sh", {
      site_fqdn = var.site_fqdn
    })
    destination = "secure.sh"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "file" {
    source = "files/server.service"
    destination = "/home/ubuntu/.config/systemd/user/server.service"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "file" {
    source = "files/backgroundworker.service"
    destination = "/home/ubuntu/.config/systemd/user/backgroundworker.service"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "file" {
    source = "files/frontend.service"
    destination = "/home/ubuntu/.config/systemd/user/frontend.service"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "file" {
    content = templatefile("templates/env", {
      site_fqdn = var.site_fqdn
      session_key = random_string.session.result
      username = var.postgresql_username
      password = random_string.password.result
      url = aws_db_instance._.endpoint
      db = aws_db_instance._.name
      s3_bucket = aws_s3_bucket.crates.bucket
      s3_bucket_sk = var.s3_secret_key
      s3_bucket_ak = var.s3_access_key
      s3_bucket_region = aws_s3_bucket.crates.region
      gh_id = var.gh_client_id
      gh_secret = var.gh_client_secret
      git_ssh_repo_url = var.git_ssh_repo_url
      git_ssh_key = tls_private_key.ssh_git_keys.private_key_pem
      git_repo_url = var.git_repo_url
    })
    destination = "/home/ubuntu/.config/crates/env"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }

  provisioner "file" {
    content = templatefile("templates/site.conf", {
      site_fqdn = var.site_fqdn
    })
    destination = "${var.site_fqdn}.conf"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }
}

resource "null_resource" "server_configure_c" {
  depends_on = [
    null_resource.server_configure_b]


  provisioner "remote-exec" {
    script = "scripts/services.sh"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key._.private_key_pem
      host = data.aws_instance.crates_server.public_ip
    }
  }
}
