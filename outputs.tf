output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.nlb.this_lb_dns_name
}

output "lb_zone_id" {
  description = "The DNS name of the load balancer."
  value       = module.nlb.this_lb_zone_id
}