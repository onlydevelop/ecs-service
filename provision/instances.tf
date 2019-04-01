# NOTE:
# Please add your public-private key pairs as
# conf/demo-key.pub
# conf/demo-key.pem
resource "aws_key_pair" "demo_key" {
  key_name   = "demo-key"
  public_key = "${file("conf/demo-key.pub")}"
}

resource "aws_instance" "bastion" {
  # Amazon Linux 2 AMI (HVM), SSD Volume Type(64-bit x86), for Mumbai
  ami                         = "ami-0889b8a448de4fc44"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = "${element(aws_subnet.public.*.id, 0)}"
  vpc_security_group_ids      = ["${aws_security_group.public_sg.id}"]
  key_name                    = "${aws_key_pair.demo_key.id}"

  tags = {
    Name = "Demo: Bastion"
    provisioned_by = "Dipanjan"
  }
}

resource "null_resource" "pem_copy" {
  provisioner "file" {
    source      = "conf/demo-key.pem"
    destination = "/home/ec2-user/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("conf/demo-key.pem")}"
      host        = "${aws_instance.bastion.public_ip}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ec2-user/.ssh/id_rsa"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("conf/demo-key.pem")}"
      host        = "${aws_instance.bastion.public_ip}"
    }
  }

  triggers {
    on_key_change = "${md5(file("conf/demo-key.pem"))}"
  }
}
