# AWS Terraform provider 5.45.0 용 IAM 모듈

* 메인 컨셉

    1. 원격 모듈 사용 (git repo, terraform registry 등)
    2. 변수 분리 tfvars 파일 policy json 파일과 csv 파일 사용
    3. 모듈 호출 구문 단순화

* 경로 구조

    각 환경별 폴더 구조는 아래와 같음.

    ```text
    <env>-iam/
    ├── groups/                 # 그룹 설정 csv 파일 저장 폴더 
    ├── policy_files/           # 각 보안정책에 사용할 Json 파일 저장 폴더
    │     ├──user_policies      # 사용자 보안정책 폴더
    │     ├──group_policies     # 그룹 보안정책 폴더
    │                  저장 폴더
    ├── iam_csv_files           # csv 파일 저장 폴더 users.csv, groups.csv
    │ main.tf                   # 모듈 호출 main 파일
    │ <env>-iam.auto.tfvars # 변수 값 저장 파일
    │ provider.tf               # provider 버전 설정 파일
    │ variables.tf              # 변수형(Type) 지정 파일

    ```

* 각 폴더별 사용 방법

  * iam_csv_files

   ```text
    * users.csv 파일 내용을 아래와 같이 사용한다.

    username,policies,groups
    prod-file-bak-user,"prod-file-bak-access-policy,Force_IP_Restriction_file_bak","dev,ops"

    ----------------------------------------------------------------
    여러개의 정책 사용시 연결할 정책을 "," 로 구분하여 " " 안에 넣는다.

    users 모듈에서 사용자를 기준으로 group 연결을 한눈에 보고 등록/삭제 할 수 있도록 코드 수정

    * groups.csv 파일 내용을 아래와 같이 사용한다.

    group_name,policies
    dev,"prod-file-bak-access-policy,Force_IP_Restriction_file_bak"
    여러개의 정책 사용시 연결할 정책을 "," 로 구분하여 " " 안에 넣는다.
    
    groups 모듈에서는 그룹과 그룹 정책만 관리한다.
    ```

  * policy_files/

    각 서브폴더 user_policies, group_policies 에 용도에 맞게 정책 이름으로 사용할 파일명의 json 파일을 문법에 맞도록 넣어준다.

