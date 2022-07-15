# output "public_ip" {
#   value       = aws_instance.web_server.public_ip
#   description = "The public IP of the web server"
# }


output "clb_dns_name" {
  value       = aws_elb.web_server_elb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
output "clb_dns_name" {
  value       = aws_elb.example.dns_name
  description = "The domain name of the load balancer"
}
