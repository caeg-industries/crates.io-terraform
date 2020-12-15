provider "aws" {
  region = var.region
}

resource "aws_vpc" "cratesvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Group = var.group_tag
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cratesvpc.id

  tags = {
    Group = var.group_tag
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.cratesvpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Group = var.group_tag
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.cratesvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Group = var.group_tag
  }
}

# Database Subnet
resource "aws_subnet" "database_subnet" {
  vpc_id = aws_vpc.cratesvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[2]

  tags = {
    Group = var.group_tag
  }
}

# EIP
resource "aws_eip" "nat" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Group = var.group_tag
  }
}

# NAT Gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Group = var.group_tag
  }
}

# public subnet route table
resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.cratesvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Group = var.group_tag
  }
}

# public subnet route table association
resource "aws_route_table_association" "public_subnet_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}


# private subnet route table
resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.cratesvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Group = var.group_tag
  }
}

# private subnet route table association
resource "aws_route_table_association" "private_subnet_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}

# database subnet route table
resource "aws_route_table" "database_subnet_route_table" {
  vpc_id = aws_vpc.cratesvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Group = var.group_tag
  }
}

resource "aws_route_table_association" "database_subnet_route_table_association" {
  subnet_id      = aws_subnet.database_subnet.id
  route_table_id = aws_route_table.database_subnet_route_table.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "bastion_host_sg" {
  name   = "bastion_host_sg"
  vpc_id = aws_vpc.cratesvpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Group = var.group_tag
  }
}

resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  availability_zone = var.availability_zones[0]

  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair._.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_host_sg.id]

  root_block_device {
    volume_size = 50
  }

  tags = {
    Group = var.group_tag
  }
}

resource "tls_private_key" "_" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_key" {
  content     = tls_private_key._.private_key_pem
  file_permission = "0400"
  filename = var.key_name
}

resource "null_resource" "create_base64_version_of_key" {
  depends_on = [local_file.ssh_key]
  provisioner "local-exec" {
    command = "cat ${var.key_name} | base64 | tr -d \\n > ${var.key_name}.b64"
  }
}

data "local_file" "b64_key" {
  depends_on = [null_resource.create_base64_version_of_key]
  filename = "${var.key_name}.b64"
}

resource "aws_key_pair" "_" {
  key_name   = var.key_name
  public_key = tls_private_key._.public_key_openssh

  tags = {
    Group = var.group_tag
  }
}

locals {
  resource_name_prefix = "${var.namespace}-${var.resource_tag_name}"
}

resource "aws_db_subnet_group" "_" {
  name       = "${local.resource_name_prefix}-${var.identifier}-subnet-group"
  subnet_ids = [aws_subnet.public_subnet.id,aws_subnet.database_subnet.id]
}

resource "aws_db_instance" "_" {
  identifier = "${local.resource_name_prefix}-${var.identifier}"
  depends_on = [aws_subnet.public_subnet]

  allocated_storage       = var.allocated_storage
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  db_subnet_group_name    = aws_db_subnet_group._.id
  engine                  = "postgres"
  engine_version          = var.postgresql_version
  instance_class          = var.postgresql_instance_class
  multi_az                = false
  name                    = var.postgresql_db
  username                = var.postgresql_username
  password                = random_string.password.result
  port                    = var.postgresql_port
  publicly_accessible     = false
  storage_encrypted       = false
  storage_type            = var.storage_type

  vpc_security_group_ids = [aws_security_group._.id]

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true

  final_snapshot_identifier = null
  snapshot_identifier       = ""
  skip_final_snapshot       = true

  performance_insights_enabled = false

  tags = {
    Group = var.group_tag
  }
}

resource "random_string" "password" {
  length  = 16
  special = false
}


resource "random_string" "session" {
  length  = 32
  special = false
}


resource "aws_security_group" "_" {
  name = "${local.resource_name_prefix}-rds-sg"

  description = "RDS (terraform-managed)"
  vpc_id      = aws_vpc.cratesvpc.id

  ingress {
    from_port   = var.postgresql_port
    to_port     = var.postgresql_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Group = var.group_tag
  }
}

data "aws_canonical_user_id" "current_user" {}

resource "aws_s3_bucket" "crates" {
  bucket = "crates-bucket"

  grant {
    id          = data.aws_canonical_user_id.current_user.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  grant {
    type        = "Group"
    permissions = ["READ"]
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.site_fqdn}"]
  }

  tags = {
    Group = var.group_tag
  }
}

resource "aws_s3_bucket_policy" "crates" {
  bucket = aws_s3_bucket.crates.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.crates.arn}/*"
    }
  ]
}
EOF
}