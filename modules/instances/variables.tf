variable "aws_region" {
  description = "리전 정보"
  type        = string
}

variable "common_tags" {
  description = "공용 tag 값 (리소스별 tags 와 병합)"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "security_groups 모듈 output (key=<vpc_name>_<sg_name>, value=sg-xxxx)"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "subnets 모듈 output (key=<vpc_name>_<subnet_name>, value=subnet-xxxx)"
  type        = map(string)
}


variable "instances" {
  description = "키=인스턴스 리소스명(Name 태그에도 사용). 값=기본 EC2 설정"
  type = map(object({
    # 필수
    ami           = string
    instance_type = string

    # 이름키로 참조 (필수급으로 쓰는 값)
    subnet_name              = string
    vpc_security_group_names = list(string) # <vpc>_<sg> 키 목록

    # 선택
    associate_public_ip_address = optional(bool)
    private_ip                  = optional(string)

    key_name             = optional(string)
    iam_instance_profile = optional(string)

    user_data = optional(string)

    # EIP 옵션(필요 시만)
    allocate_eip = optional(bool)
    eip_domain   = optional(string) # 기본 vpc

    # tags
    tags = optional(map(string))
  }))
}
