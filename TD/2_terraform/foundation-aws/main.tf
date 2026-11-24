# Étape 0 : déclaration du provider AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Étape 1 : VPC en Europe (eu-west-3 = Paris)
resource "aws_vpc" "vpc_1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "vpc-1" }
}

# Deux sous-réseaux dans deux zones de disponibilité (requis par RDS)
resource "aws_subnet" "subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = "${var.region}${["a", "b"][count.index]}"
  map_public_ip_on_launch = true

  tags = { Name = "subnet-${count.index + 1}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_1.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Groupes de sécurité : web pour les VM, MySQL accessible uniquement depuis les VM
resource "aws_security_group" "vm" {
  name   = "vm-sg"
  vpc_id = aws_vpc.vpc_1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = aws_vpc.vpc_1.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.vm.id]
  }
}

# Étape 2 + 5 : instances EC2 dans le VPC, "count" pour la haute disponibilité
resource "aws_instance" "vm" {
  count                  = var.vm_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.vm.id]

  tags = { Name = "vm-pc${count.index + 1}" }
}

# Étape 3 : base de données RDS MySQL dans le même VPC
resource "aws_db_subnet_group" "db" {
  name       = "db-subnet-group"
  subnet_ids = aws_subnet.subnet[*].id
}

resource "aws_db_instance" "db" {
  identifier             = "vbdd-1"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# Étape 4 : zone Route 53 + enregistrement DNS vers les VM
resource "aws_route53_zone" "prod" {
  name = var.dns_name
}

resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.prod.zone_id
  name    = "frontend.${var.dns_name}"
  type    = "A"
  ttl     = 300
  records = aws_instance.vm[*].public_ip
}
