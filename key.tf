resource "aws_key_pair" "media" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${var.ssh_key}"
}