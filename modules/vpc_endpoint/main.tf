locals {
  processed_endpoints = {
    for ep_key, ep in var.vpc_endpoints : ep_key => {
      vpc_id            = var.vpc_ids[ep.vpc_name]
      service_name      = ep.service_name
      vpc_endpoint_type = ep.vpc_endpoint_type
      policy            = ep.policy != null ? file("${path.root}/policy_files/${ep.policy}.policy") : null 

      route_table_ids = ep.vpc_endpoint_type == "Gateway" ? (
        length(coalesce(lookup(ep, "route_table_names", []), [])) > 0 ?
          [ for rt in coalesce(lookup(ep, "route_table_names", []), []) : lookup(var.route_table_map, rt, null) if lookup(var.route_table_map, rt, null) != null ]
          : null
      ) : null

      subnet_ids = ep.vpc_endpoint_type == "Interface" ? (
        length(coalesce(lookup(ep, "subnet_names", []), [])) > 0 ?
          [ for sn in coalesce(lookup(ep, "subnet_names", []), []) : lookup(var.subnet_map, sn, null) if lookup(var.subnet_map, sn, null) != null ]
          : null
      ) : null

      security_group_ids = ep.vpc_endpoint_type == "Interface" ? (
        length(coalesce(lookup(ep, "security_group_names", []), [])) > 0 ?
          [ for sg in coalesce(lookup(ep, "security_group_names", []), []) : lookup(var.security_group_map, sg, null) if lookup(var.security_group_map, sg, null) != null ]
          : null
      ) : null

      private_dns_enabled = ep.vpc_endpoint_type == "Interface" ? ep.private_dns_enabled : null

      tags = merge(var.common_tags, ep.tags, { "Name" = ep_key })
    }
  }
}





resource "aws_vpc_endpoint" "this" {
  for_each = local.processed_endpoints

  vpc_id            = each.value.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  route_table_ids   = each.value.route_table_ids
  subnet_ids        = each.value.subnet_ids
  security_group_ids = each.value.security_group_ids
  private_dns_enabled = each.value.private_dns_enabled

  policy            = jsoncode(each.value.policy)

  tags = each.value.tags
}
