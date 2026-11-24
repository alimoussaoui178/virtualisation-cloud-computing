variable "project_id" {
  description = "Identifiant du projet GCP"
  type        = string
}

variable "region" {
  description = "Région GCP (Europe)"
  type        = string
  default     = "europe-west9"
}

variable "zone" {
  description = "Zone GCP de la VM"
  type        = string
  default     = "europe-west9-a"
}

variable "vm_count" {
  description = "Nombre d'instances de VM (haute disponibilité)"
  type        = number
  default     = 2
}

variable "dns_name" {
  description = "Nom de domaine de la zone DNS (avec un point final)"
  type        = string
  default     = "prod.kiowy.com."
}
