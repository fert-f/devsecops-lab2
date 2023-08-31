/*

infracost breakdown --path . --show-skipped --no-color 

docker run -it --rm -v $(pwd):$(pwd) -w $(pwd) --name tfdocs quay.io/terraform-docs/terraform-docs:0.16.0 markdown --recursive . --output-file=README.md --output-mode=replace --sort-by required --anchor=true --recursive-path modules

*/
module "pki" {
  source       = "./modules/pki"
  key_name     = var.stack_name
  ssh_key_path = "~/.ssh/devsecops_aws_terraform.pem"
}
