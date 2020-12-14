//output "my-aws-instance-public-ip" {
//  value = aws_instance.bastion_host.public_ip
//}
//
//output "db_password" {
//  value = random_string.password.result
//}

output "ssh" {
  value = "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i ${var.key_name} ubuntu@${aws_instance.bastion_host.public_ip}"
}
output "git_deploy_key" {
  value = tls_private_key.ssh_git_keys.public_key_pem
}
