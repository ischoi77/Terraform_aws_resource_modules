# AWS VPC 생성 모듈

이 모듈은 AWS 에서 VPC를 생성 하는 모듈이다.

## Table of Contents

- [Overview][1]
- [Example Input][2]
- [Requirements][3]
- [Inputs][4]
- [Outputs][5]
- [Modules][6]
- [Resources][7]

## Overview

기본 cidr 와 추가 cidr 을 입력할 수 있도록 구성되어 있다.



## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS 리전 | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | 모든 리소스에 공통으로 적용할 태그 | `map(string)` | n/a | yes |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | VPC 생성 정보를 담은 map(object). 각 key는 VPC 이름 | <pre>map(object({<br/>    cidr_block       = string<br/>    additional_cidrs = list(string)  # 추가 CIDR 블록 목록 (없으면 빈 리스트)<br/>    tags             = map(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_ids"></a> [vpc\_ids](#output\_vpc\_ids) | 생성된 VPC ID 목록 (key: 리소스 이름) |
| <a name="output_vpc_ipv4_cidr_association_ids"></a> [vpc\_ipv4\_cidr\_association\_ids](#output\_vpc\_ipv4\_cidr\_association\_ids) | VPC에 추가된 IPv4 CIDR 블록 할당 ID 목록 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_dhcp_options.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_ipv4_cidr_block_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |

[1]: #overview
[2]: #example-input
[3]: #requirements
[4]: #inputs
[5]: #outputs
[6]: #modules
[7]: #resources
