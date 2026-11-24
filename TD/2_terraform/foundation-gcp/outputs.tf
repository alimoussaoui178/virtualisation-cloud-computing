output "vm_public_ips" {
  description = "IP publiques des VM"
  value       = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}

output "db_connection_name" {
  description = "Nom de connexion de la base Cloud SQL"
  value       = google_sql_database_instance.db.connection_name
}

output "frontend_fqdn" {
  description = "Nom DNS du frontend"
  value       = google_dns_record_set.frontend.name
}
