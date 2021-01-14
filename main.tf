locals {
  vpc_id       = var.vpc_id
  env          = var.env
  name         = var.name
  instance_type= var.instance_type
  aws = {
    key = var.aws_key
    secret = var.aws_secrect
  }
  region = var.region
  pre_shell ={
    rabbit_init = <<EOF
      #cloud-config
      repo_update: true

      packages:
      - curl
      - wget
      - vim

      runcmd:
      - echo "start"
      - curl -L https://.sh | sed 's/owt/${local.name}-rabbit-${local.env}/g' | REGION="${local.region}" SVC_ENV="${local.env}" AWS_ID="${local.aws.key}" AWS_SECRET="${local.aws.secret}" sh
      - rabbitmq-plugins --offline enable rabbitmq_management rabbitmq_peer_discovery_aws
      - echo "CCSCYBELKXATHBUVDTEK" | tee /var/lib/rabbitmq/.erlang.cookie
      - systemctl restart rabbitmq-server
      - rabbitmqctl stop_app
      - rabbitmqctl reset
      - rabbitmqctl start_app
      - rabbitmqctl add_user ${var.rabbit_user} ${var.rabbit_pw}
      - rabbitmqctl set_user_tags ${var.rabbit_user} administrator
      - rabbitmqctl set_permissions ${var.rabbit_user} ".*" ".*" ".*"
    EOF
  }
  sg_id = var.sg_id #for private
  default_tags = var.tags
  subnet_ids = var.subnet_ids
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  is_internal         = var.is_internal
  ssh_key             = var.ssh_key
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20210105"]
    #values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    #ami_id = "ami-0d2d2286f0655e95e"
  }
}


module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  
  name = "${local.name}-${local.env}-rb-nlb"

  load_balancer_type = "network"
  internal = var.is_internal
  vpc_id  = local.vpc_id
  subnets = local.subnet_ids
  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "TCP"
      backend_port     = 5672
      target_type      = "instance"
    },
    {
      name_prefix      = "pref-"
      backend_protocol = "TCP"
      backend_port     = 15672
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 5672
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 1
    }
  ]

  tags =merge(local.default_tags, {
    "purpose" = "rabbitmq"
  })
}


module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"
  
  name = "${local.name}-rabbit-${local.env}"

  # Launch configuration
  lc_name = "${local.name}-${local.env}-rabbit"
  image_id                  = data.aws_ami.ubuntu-18_04.id
  instance_type             = local.instance_type
  security_groups           = [local.sg_id]
  desired_capacity          = local.desired_capacity
  max_size                  = local.max_size
  min_size                  = local.min_size
  key_name                  = local.ssh_key
  root_block_device = [
    {
      volume_size = "30"
      volume_type = "gp2"
    },
  ]
  target_group_arns = module.nlb.target_group_arns
  # Auto scaling group
  asg_name                  = "rabbit-${local.env}-asg"
  vpc_zone_identifier       = local.subnet_ids
  health_check_type         = "EC2"
  wait_for_capacity_timeout = 0
  user_data_base64 = base64encode(local.pre_shell.rabbit_init)
  tags = []
  tags_as_map = merge(local.default_tags, {
    "project" = "${local.name}-rabbit-${local.env}"
    "name" = "${local.name}-rabbit-${local.env}"
    "Name" = "${local.name}-rabbit-${local.env}"
    "rabbit" = "1" # for peer discovery
  })  
}

