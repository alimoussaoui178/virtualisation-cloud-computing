variable "region" {
  description = "Région AWS (Europe - Paris)"
  type        = string
  default     = "eu-west-3"
}

variable "vm_count" {
  description = "Nombre d'instances EC2 (haute disponibilité)"
  type        = number
  default     = 2
}

variable "ami_id" {
  description = "AMI de la VM (Debian 12 / Ubuntu dans eu-west-3)"
  type        = string
  default     = "ami-0160e8d70ebc43ee1"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "db_password" {
  description = "Mot de passe administrateur de la base (à fournir via TF_VAR_db_password)"
  type        = string
  sensitive   = true
  default     = "ChangeMe-TD2-only"
}

variable "dns_name" {
  description = "Nom de domaine de la zone Route 53"
  type        = string
  default     = "prod.kiowy.com"
}
