output "elb_dns_name" {
  value       = aws_elb.elb-task1.dns_name
  description = "The domain name of the load balancer"
}
