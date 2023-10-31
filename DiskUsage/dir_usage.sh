#!/bin/bash
#Amazon Linux release 2
#This script using for disk usage check For Devops Team

echo "
디스크 사용량 체크를 위한 스크립트 입니다.
체크 할 디렉토리의 path와 depth를 설정 후 사용량 체크할 수 있습니다.
"

read -p "Tell me about Directory Path for Check: " val1

# 디렉토리 사용량 체크를 위한 depth 설정
read -p "Input the Depth (Please enter the value as a number) : " val2
echo "Depth selected: $val2 "

# Total directory usage(GB)
total_usage=$(du -sh $val1 2>/dev/null | awk '{print$1}')

# directory usage(GB) & mount point check
usage_info=$(du -h $val1 --max-depth=$val2 2>/dev/null | sort -k 1,1hr | head -n 10)

# directory usage check (KB)
usage_info_k=$(du -k $val1 --max-depth=$val2 2>/dev/null | sort -k 1,1hr | head -n 10)

# 각 디렉토리의 사용량 & 디스크 정보 변수에 저장
usage_values=()
usage_values_k=()
usage_persent=()

dir_path_values=()
disk_mount_point=()
disk_size=()

# 디렉토리 경로와 사용공간(GB)를 변수에 저장
while IFS= read -r line; do

    dir_path=$(echo $line | awk '{print $2}')

    if [ $dir_path == / ]; then
        dir_size=$(du -sh -x / 2>/dev/null | awk '{print$1}')
    else
        dir_size=$(echo $line | awk '{print $1}')
    fi

    mount_point=$(df $dir_path | awk 'NR==2{print $6}')
    disk_size_g=$(df -h $dir_path | awk 'NR==2{print $2}')

    usage_values+=("$dir_size")
    dir_path_values+=("$dir_path")
    disk_mount_point+=("$mount_point")
    disk_size+=("$disk_size_g")

done <<< "$usage_info"

# 디렉토리 사용량(%)을 변수에 저장
while IFS= read -r line; do

    dir_path_k=$(echo $line | awk '{print $2}')

    if [ $dir_path_k == / ]; then
        dir_size_k=$(du -sk -x / 2>/dev/null | awk '{print$1}')
    else
        dir_size_k=$(echo $line | awk '{print $1}')
    fi

    disk_size_k=$(df -k $dir_path_k | awk 'NR==2{print $2}')

    percent=$(awk "BEGIN { printf \"%.1f\", (($dir_size_k / $disk_size_k) * 100) }")
    usage_percent+=("$percent")

done <<< "$usage_info_k"

# 사용량(GB,%) & 경로 출력
#
echo "($val1) total space is : $total_usage"
printf "%-10s\t%-10s\t%-15s\t%-5s\n" "Disk Size" "Used (%)" "Mount Point" "Path"
for i in "${!usage_values[@]}"; do
        printf "%-10s\t%-10s\t%-15s\t%-5s\n" ${disk_size[$i]}"" "${usage_values[$i]} (${usage_percent[$i]}%)" "${disk_mount_point[$i]}" "${dir_path_values[$i]}"
done
