"""
Title: 대규모 infra 구성 및 관리를 위한 AWS 리소스 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-07-29
Description: SG rule 간편 에디터
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v1.0.0
"""



import csv
import os
import argparse
from pathlib import Path
from datetime import datetime

COMPARE_FIELDS = ['VPC_Name', 'SG_Name', 'Direction', 'Protocol', 'Port', 'SG_ID_or_CIDR']
ALL_FIELDS = COMPARE_FIELDS + ['Rule_Description']
LOWER_FIELDS = {'Direction', 'Protocol'}

SCRIPT_DIR = Path(__file__).resolve().parent
SG_DIR = SCRIPT_DIR.parent / "vpc_sg_rules"
LOG_FILE = SCRIPT_DIR / "sg_rule_log.txt"
ADD_FILE = SCRIPT_DIR / "sg_rule_adds.csv"
REMOVE_FILE = SCRIPT_DIR / "sg_rule_removes.csv"

def normalize_rule(fields):
    return tuple(
        fields[i].strip().lower() if COMPARE_FIELDS[i] in LOWER_FIELDS else fields[i].strip()
        for i in range(len(COMPARE_FIELDS))
    )

def read_csv_as_rule_set(file_path):
    if not file_path.exists():
        return set()
    with open(file_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        return {normalize_rule([row[field] for field in COMPARE_FIELDS]) for row in reader}

def rule_to_str(rule_tuple):
    return ','.join(rule_tuple)

def write_log(lines):
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.writelines([line + '\n' for line in lines])

def get_target_sg_files(add_rules, remove_rules):
    target_sgs = {(r[0].strip(), r[1].strip()) for r in add_rules | remove_rules}
    return sorted(target_sgs)

def modify_sg_rules(add_rules, remove_rules, dry_run=False):
    logs = []
    logs.append(f"=== SG Rule Update Start: {datetime.now().isoformat()} (dry_run={dry_run}) ===\n")

    target_sg_keys = get_target_sg_files(add_rules, remove_rules)

    for vpc_name, sg_name in target_sg_keys:
        vpc_dir = SG_DIR / vpc_name
        sg_file = vpc_dir / f"{sg_name}.csv"

        if not sg_file.exists():
            logs.append(f"⚠️ 대상 없음: {vpc_name}/{sg_name}.csv (파일 없음)")
            continue

        logs.append(f"\n📂 처리 중: {vpc_name}/{sg_name}.csv")

        with open(sg_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            fieldnames = reader.fieldnames or []

        def row_key(row):
            return normalize_rule([
                vpc_name,
                sg_name,
                row['Direction'],
                row['Protocol'],
                row['Port'],
                row['SG_ID_or_CIDR']
            ])

        current_keys = {row_key(row) for row in rows}

        # 삭제
        filtered_rows = []
        deleted_rules = []
        for row in rows:
            key = row_key(row)
            if key in remove_rules:
                deleted_rules.append(key)
            else:
                filtered_rows.append(row)

        # 추가
        current_keys_after_delete = {row_key(row) for row in filtered_rows}
        added_rules = []
        skipped_rules = []

        for rule in add_rules:
            rvpc, rsg = rule[0].strip(), rule[1].strip()
            if rvpc != vpc_name or rsg != sg_name:
                continue
            if rule not in current_keys_after_delete:
                added_rules.append(rule)
            else:
                skipped_rules.append(rule)

        logs.append(f" - 삭제: {len(deleted_rules)}건")
        for rule in deleted_rules:
            logs.append(f"   - 삭제됨: {rule_to_str(rule)}")
        logs.append(f" - 추가: {len(added_rules)}건")
        for rule in added_rules:
            logs.append(f"   + 추가됨: {rule_to_str(rule)}")
        logs.append(f" - 중복 제외: {len(skipped_rules)}건")
        for rule in skipped_rules:
            logs.append(f"   = 중복 생략: {rule_to_str(rule)}")

        # 저장
        updated_rows = filtered_rows[:]
        for rule in added_rules:
            row_dict = dict(zip(COMPARE_FIELDS, rule))
            row_dict.setdefault('Rule_Description', '')
            for field in fieldnames:
                row_dict.setdefault(field, '')
            updated_rows.append(row_dict)

        updated_rows.sort(key=lambda r: tuple(
            r[field].lower() if field in LOWER_FIELDS else r[field] for field in COMPARE_FIELDS[2:]
        ))

        if not dry_run:
            with open(sg_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(updated_rows)

    logs.append(f"\n=== SG Rule Update End ===\n")
    write_log(logs)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true', help='파일을 수정하지 않고 비교 로그만 출력합니다.')
    args = parser.parse_args()

    add_rules = read_csv_as_rule_set(ADD_FILE)
    remove_rules = read_csv_as_rule_set(REMOVE_FILE)

    modify_sg_rules(add_rules, remove_rules, dry_run=args.dry_run)

if __name__ == "__main__":
    main()
