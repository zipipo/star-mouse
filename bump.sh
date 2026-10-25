#!/bin/sh
# 배포 전에 버전 문자열 갱신
V=$(date +%Y%m%d%H%M%S)
sed -i "s/const VER='[^']*'/const VER='$V'/" index.html
echo "$V" > version.txt
