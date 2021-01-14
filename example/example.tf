
module rabbit {
  source          = "./rabbit"
  name            = local.name
  env             = local.env
  vpc_id          = data.terraform_remote_state.remote.outputs.frankfurt-infra.vpc.id
  sg_id           = module.security-group.sg_private
  subnet_ids      = data.terraform_remote_state.remote.outputs.frankfurt-infra.vpc.public_subnets
  region          = data.aws_region.current.name
  instance_type   = "t3.small"
  aws_key         = local.aws_key
  aws_secrect     = local.aws_secrect
  ssh_key         = "key"
  rabbit_user     = "admin"
  rabbit_pw       = "admin"
  tags    = local.tags
}

module route53-rabbit {
  source  = "../../route53"
  zone_id = data.aws_route53_zone.mvb_cloud.zone_id
  records = {
    "rabbit.example.com"             = { type = "A" }
  }
  lb_dns_name = module.rabbit.lb_dns_name
  lb_zone_id  = module.rabbit.lb_zone_id
}