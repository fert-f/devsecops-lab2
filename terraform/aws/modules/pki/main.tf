resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name # Create "myKey" to AWS!!
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_sensitive_file" "pem_file" {
  filename             = pathexpand(var.ssh_key_path)
  file_permission      = "600"
  directory_permission = "700"
  content              = tls_private_key.this.private_key_pem
}