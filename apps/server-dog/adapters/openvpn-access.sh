#!/bin/bash

# OpenVPN ServerDog Adapter Script
# Этот адаптер предназначен информации которая далее может быть использована в dashboard.sh

# Берется openvpn-status.log, уникальные IP, для каждого IP берется дата последнего обращения. 
# Скрипт для получения IP и даты последнего обращения из openvpn-status.log OpenVPN.
LOG_FILE="/var/log/openvpn-status.log"  # Путь к файлу openvpn-status.log
OUTPUT_FILE="/var/log/openvpn/ip_lastdate.txt"  # Путь к выходному файлу, где будут сохранены результаты
if [ ! -f "$LOG_FILE" ]; then
    echo "Файл $LOG_FILE не найден!"
    exit 1
fi      
# Извлекаем уникальные IP и дату последнего обращения
awk '/^CLIENT_LIST/ {print $3, $7}' "$LOG_FILE" | \
    sort -u | \  # Сортируем и удаляем дубликаты
    awk '{ip[$1]=$2} END {for (i in ip) print i, ip[i]}' | \
    sort -k2,2r > "$OUTPUT_FILE"  # Сортируем по дате в обратном порядке    
echo "Результаты сохранены в $OUTPUT_FILE" 

# Выводим результаты на экран
echo "Последние обращения по IP:"
cat "$OUTPUT_FILE"
# Выводим количество уникальных IP
unique_ips=$(wc -l < "$OUTPUT_FILE")
echo "Количество уникальных IP: $unique_ips" 