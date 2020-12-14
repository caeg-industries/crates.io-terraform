output "ssh" {
  value = "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i ${var.key_name} ubuntu@${aws_instance.bastion_host.public_ip}"
}
output "dns" {
  value = "Required DNS: ${var.site_fqdn} IN A ${aws_instance.bastion_host.public_ip}"
}
