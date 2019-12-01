data "template_file" "script" {
    template = "${file("script.tpl")}"

    vars {
        transmission_passwd = "${var.transmission_passwd}"
        my_ip               = "${var.my_ip}"
        plex_claim          = "${var.plex_claim}"
    }
}