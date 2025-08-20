# AWS Terraform provider 5.45.0 용 모듈

* 메인 컨셉

    1. 원격 모듈 사용 (git repo, terraform registry 등)
    2. 변수 분리 및 list file 및 csv 파일 사용
    3. 모듈 호출 구문 단순화

* 경로 구조

    각 리전별 폴더 구조는 아래와 같음.

    ```text
    <env>-<region>/
    ├── ip_lists/               # 라우팅에 사용할 IP 리스트 저장 폴더
    ├── network_csv_files/      # 서브넷 생성에 사용할 CSV 파일 저장 폴더
    ├── policy_files/           # 각 보안정책에 사용할 Json 파일 저장 폴더
    ├── vpc_sg_rules/           # SG 생성및 SG Rule 생성에 사용할 CSV 파일 저장 폴더
    │
    main.tf                     # 모듈 호출 
    <env>-<region>.auto.tfvars  # 변수 값 저장 파일
    provider.tf                 # provider 버전 설정 파일
    variables.tf                # 변수형(Type) 지정 파일


    ```

* 각 폴더별 사용 방법

  * ip_lists/

        1. 사용할 IP(cidr)를 줄(Line) 단위로 넣는다.
        2. 주의 사항 줄 바꿈 문자 "\n" 을 파싱하기 때문에 단 한 줄이라도 입력시 꼭 줄바꿈을 해주어야 한다. 

  * network_csv_files/

        1. 각 CSV 파일을 헤더 값에 맞도록 입력해준다.  
        2. nat의 경우 다음과 같고 key1 ~ 4, value1 ~ 4 는 필수 Tag 인 class0,1 GBL_CLASS_0,1 를 위해 설정됨
            * nat_gateway_name,subnet,public,allocation_id,key1,value1,key2,value2,key3,value3,key4,value4
        3. subnet의 경우 vpc,name,cidr

  * policy_files/

        1. json 문법에 맞도록 json 파일을 넣어준다.

  * vpc_sg_rules/

        1. VPC 이름에 따라 서브폴더로 구분 하고
        2. 파일의 이름은 security_group 의 이름이 되고 내용은 Rule 로 등록된다.
        3. CSV 헤더는 다음과 같다.
            * VPC_Name,SG_Name,Direction,Protocol,Port,SG_ID_or_CIDR,Rule_Description


* 개선 사항 (from v3.40.0)
    1. SG rule 관련 로직 개선 (self rule 관련)