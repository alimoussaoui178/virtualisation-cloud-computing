# Étape 0 : déclaration du provider Google
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Étape 1 : VPC (réseau privé) en Europe
resource "google_compute_network" "vpc_1" {
  name                    = "vpc-1"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_1" {
  name          = "subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_1.id
}

# Étape 2 : instance Compute Engine dans le VPC
# Étape 5 : meta-argument "count" => plusieurs VM pour la haute disponibilité
resource "google_compute_instance" "vm" {
  count        = var.vm_count
  name         = "vm-pc${count.index + 1}"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_1.id
    subnetwork = google_compute_subnetwork.subnet_1.id
    access_config {} # IP publique pour l'enregistrement DNS
  }
}

# Étape 3 : base de données Cloud SQL dans le même VPC (IP privée)
# Plage d'IP réservée pour le peering entre le VPC et les services Google
resource "google_compute_global_address" "private_ip_db" {
  name          = "private-ip-db"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_1.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_1.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_db.name]
}

resource "google_sql_database_instance" "db" {
  name                = "vbdd-1"
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_1.id
    }
  }
}

# Étape 4 : zone DNS + enregistrement A vers la VM
resource "google_dns_managed_zone" "prod" {
  name     = "prod-zone"
  dns_name = var.dns_name
}

resource "google_dns_record_set" "frontend" {
  name         = "frontend.${google_dns_managed_zone.prod.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.prod.name

  # Une IP par VM : le DNS répartit le trafic entre les instances
  rrdatas = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}
