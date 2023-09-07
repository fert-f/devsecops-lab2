data "template_file" "this" {
  template               = file("${path.cwd}/../../user-data/templates/${var.file}")
  vars = var.vars
}
