output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "security_group_id" {
  value = aws_security_group.example_security_group.id
}

output "instances_in_az" {
  value = aws_subnet.public.availability_zone
}
