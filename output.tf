output "instance_ip" {
  value = "${aws_instance.media-server.public_ip}"
}
