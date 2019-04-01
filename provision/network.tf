# Configure the AWS Provider
provider "aws" {
  profile = "profile-ap-south-1"
  region  = "ap-south-1"
  version = "1.0"
}

# List of availability zones
data "aws_availability_zones" "available" {}

# Variables
variable az_count {default = 2}

# The virtual private network in AWS
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Demo: VPC"
    provisioned_by = "Dipanjan"
  }
}

# The public subnet
resource "aws_subnet" "public" {
  count = "${var.az_count}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "Demo: Public Subnet"
    provisioned_by = "Dipanjan"
  }
}

# The internet gateway for public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "Demo: Internet Gateway"
    provisioned_by = "Dipanjan"
  }
}

# The route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "Demo: Public Route Table"
    provisioned_by = "Dipanjan"
  }
}

# Associate the public route table with public subnet
resource "aws_route_table_association" "public_route_association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

# Security group for public subnet
resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "Public Security Group"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.11.0/24"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = ["10.0.10.0/24"]
  }

  egress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = ["10.0.11.0/24"]
  }

  tags = {
    Name = "Demo: Public Security Group"
    provisioned_by = "Dipanjan"
  }
}

# The private subnet for app
resource "aws_subnet" "private" {
  count = "${var.az_count}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  tags = {
    Name = "Demo: Private Subnet"
    provisioned_by = "Dipanjan"
  }
}

# Public IP for the nat gateway
resource "aws_eip" "nat_gw_ip" {
  count = "${var.az_count}"
  vpc = true
}

# Nat gateway for private subnet
resource "aws_nat_gateway" "nat_gw" {
  count = "${var.az_count}"
  allocation_id = "${element(aws_eip.nat_gw_ip.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.igw"]
}

# Route table for the private subnet
resource "aws_route_table" "private_route_table" {
  count = "${var.az_count}"
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"
  }

  tags {
    Name = "Demo: Private Route Table"
    provisioned_by = "Dipanjan"
  }
}

# Associate the private route table with private subnet
resource "aws_route_table_association" "private_route_association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private_route_table.*.id, count.index)}"
}

# Security group for private subnet
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Private Security Group"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Demo: Private Security Group"
    provisioned_by = "Dipanjan"
  }
}

# Security group for load balancer
resource "aws_security_group" "lb_sg" {
  name        = "load_balancer_sg"
  description = "Load Balancer Security Group"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Demo: Load Balancer Security Group"
    provisioned_by = "Dipanjan"
  }
}
