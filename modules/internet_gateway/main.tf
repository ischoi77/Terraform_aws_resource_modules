/*
Title: SPCv2 Internet-Gateway module
Author: Inseok-Choi
contect: is25.choi@partner.samsung.com, ischoi.scloud@gmail.com

*/


# 입력받은 각 인터넷 게이트웨이 객체에 대해 vpc_name을 기준으로 VPC ID를 조회합니다.
# data "aws_vpc" "selected" {
#   for_each = var.internet_gateways

#   filter {
#     name   = "tag:Name"
#     values = [each.value.vpc_name]
#   }
# }

resource "aws_internet_gateway" "this" {
  for_each = var.internet_gateways

  # 데이터 소스를 통해 조회된 VPC ID를 사용합니다.
  # VPC 모
  vpc_id = var.vpc_ids[each.value.vpc_name]
  tags = merge(
    var.common_tags,
    { "Name" = each.key },
    each.value.tags
  )
}