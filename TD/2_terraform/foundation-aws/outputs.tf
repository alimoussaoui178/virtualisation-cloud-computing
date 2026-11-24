output "vm_public_ips" {
  description = "IP publiques des instances EC2"
  value       = aws_instance.vm[*].public_ip
}

output "db_endpoint" {
  description = "Endpoint de la base RDS"
  value       = aws_db_instance.db.endpoint
}

output "frontend_fqdn" {
  description = "Nom DNS du frontend"
  value       = aws_route53_record.frontend.fqdn
}
