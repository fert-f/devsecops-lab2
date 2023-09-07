/*

infracost breakdown --path . --show-skipped --no-color 

docker run -it --rm -v $(pwd):$(pwd) -w $(pwd) --name tfdocs quay.io/terraform-docs/terraform-docs:0.16.0 markdown --recursive . --output-file=README.md --output-mode=replace --sort-by required --anchor=true --recursive-path modules

*/

# resource "aws_lb" "this" {
#   name        = "ALB"
# }