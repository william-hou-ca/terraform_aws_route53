terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
	region = "ca-central-1"
}

####################################################################################
#
# main public zone
#
####################################################################################

resource "aws_route53_zone" "main" {
  name = var.host_zone_name
}

####################################################################################
#
# add a record to the zone using Simple routing policy
#
####################################################################################

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.host_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["1.1.1.1"]
}

####################################################################################
#
# add a record to the zone using Weighted routing policy
#
####################################################################################

resource "aws_route53_record" "wr_west" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "wr"
  type    = "A"
  ttl     = "300"

  weighted_routing_policy {
    weight = 60
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "west"
  records        = ["192.168.0.1"]
}

resource "aws_route53_record" "wr_east" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "wr"
  type    = "A"
  ttl     = "300"

  weighted_routing_policy {
    weight = 90
  }

  set_identifier = "east"
  records        = ["192.168.0.2"]
}

####################################################################################
#
# add a record to the zone using Alias record
#
####################################################################################

resource "aws_route53_record" "ali" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "ali"
  type    = "A"

  alias {
    name                   = aws_route53_record.www.name
    zone_id                = aws_route53_zone.main.zone_id
    evaluate_target_health = true
  }
}

####################################################################################
#
# add a record to the zone using failover routing policy
#
####################################################################################

resource "aws_route53_record" "fr_pri" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "fr"
  type    = "A"
  ttl     = "300"

  failover_routing_policy  {
    type = "PRIMARY"
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "primary"
  records        = ["192.168.0.1"]

  health_check_id = aws_route53_health_check.fr_heathcheck.id
}

resource "aws_route53_record" "fr_sec" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "fr"
  type    = "A"
  ttl     = "300"

  failover_routing_policy  {
    type = "SECONDARY"
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "secondary"
  records        = ["192.168.0.2"]
}

resource "aws_route53_health_check" "fr_heathcheck" {
  fqdn              = "fr.${var.host_zone_name}"
  #ip_address = local.fr_primary_ip_add
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "tf-failoverpolicy-health-check"
  }
}

####################################################################################
#
# add a record to the zone using geolocation routing policy
#
####################################################################################

resource "aws_route53_record" "geo_na" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "geo"
  type    = "A"
  ttl     = "300"

  geolocation_routing_policy  {
    continent = "NA"
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "Nother america"
  records        = ["192.168.0.1"]
}

resource "aws_route53_record" "geo_others" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "geo"
  type    = "A"
  ttl     = "300"

  geolocation_routing_policy  {
    country = "*"
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "other continets"
  records        = ["192.168.0.2"]
}

####################################################################################
#
# add a record to the zone using latency routing policy
#
####################################################################################

resource "aws_route53_record" "lat_ca" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "lat"
  type    = "A"
  ttl     = "300"

  latency_routing_policy  {
    region = "ca-central-1"
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "canada"
  records        = ["192.168.0.1"]
}

resource "aws_route53_record" "lat_eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "lat"
  type    = "A"
  ttl     = "300"

  latency_routing_policy  {
    region = "eu-central-1"
  }

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "europe"
  records        = ["192.168.0.2"]
}

####################################################################################
#
# add a record to the zone using multivalue answer routing policy
#
####################################################################################

resource "aws_route53_record" "mult" {
  count = 3
  zone_id = aws_route53_zone.main.zone_id
  name    = "mult"
  type    = "A"
  ttl     = "300"

  multivalue_answer_routing_policy = true

  #Set_identifier is named as Record ID in aws web console
  set_identifier = "multivalue answer-${count.index}"
  records        = [format("192.168.0.%s", tostring(count.index + 1))]
}


####################################################################################
#
# add a Public Subdomain Zone
#
####################################################################################

resource "aws_route53_zone" "dev" {
  name = "dev.${var.host_zone_name}"

  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "dev-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "dev"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.dev.name_servers
}

resource "aws_route53_record" "dev-www" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = "www.dev.${var.host_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["8.8.8.8"]
}

####################################################################################
#
# create a Private Zone
#
####################################################################################
/*
resource "aws_route53_zone" "private" {
  name = "example.com"

  vpc {
    vpc_id = aws_vpc.example.id
  }
}
*/