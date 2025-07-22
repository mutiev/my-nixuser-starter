#!/bin/bash

# NGINX ServerDog Adapter Script
# Этот адаптер предназначен информации которая далее может быть использована в dashboard.sh


# Берется access.log, уникальные IP, для каждого IP берется дата последнего обращения.
# Скрипт для получения IP и даты последнего обращения из access.log Nginx.
LOG_FILE="/var/log/nginx/access.log"  # Путь к файлу access.log
OUTPUT_FILE="/var/log/nginx/ip_lastdate.txt"  # Путь к выходному
# файлу, где будут сохранены результаты
if [ ! -f "$LOG_FILE" ]; then
    echo "Файл $LOG_FILE не найден!"
    exit 1
fi

# Извлекаем уникальные IP и дату последнего обращения
awk '{print $1, $4}' "$LOG_FILE" | \
    sed 's/\[//; s/\]//' | \  # Удаляем квадратные скобки
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
# Выводим дату последнего обращения
last_date=$(awk '{print $2}' "$OUTPUT_FILE" | head -n 1)
echo "Дата последнего обращения: $last_date"
# Выводим количество обращений
total_requests=$(wc -l < "$LOG_FILE")
echo "Общее количество обращений: $total_requests"
# Выводим количество обращений по каждому IP
echo "Количество обращений по каждому IP:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | while read count ip; do
    echo "$ip: $count"
done    
# Выводим количество обращений за последние 24 часа
last_24h=$(awk -v date="$(date -d '24 hours ago' '+[%d/%b/%Y:%H:%M:%S')" '$4 > date {print $1}' "$LOG_FILE" | wc -l)
echo "Количество обращений за последние 24 часа: $last_24h"     
# Выводим количество обращений за последние 7 дней
last_7d=$(awk -v date="$(date -d '7 days ago' '+[%d/%b/%Y:%H:%M:%S')" '$4 > date {print $1}' "$LOG_FILE" | wc -l)
echo "Количество обращений за последние 7 дней: $last_7d"
# Выводим количество обращений за последние 30 дней
last_30d=$(awk -v date="$(date -d '30 days ago' '+[%d/%b/%Y:%H:%M:%S')" '$4 > date {print $1}' "$LOG_FILE" | wc -l)
echo "Количество обращений за последние 30 дней: $last_30d"
# Выводим количество обращений за последние 90 дней 
last_90d=$(awk -v date="$(date -d '90 days ago' '+[%d/%b/%Y:%H:%M:%S')" '$4 > date {print $1}' "$LOG_FILE" | wc -l)
echo "Количество обращений за последние 90 дней: $last_90d"             
# Выводим количество обращений за последние 180 дней
last_180d=$(awk -v date="$(date -d '180 days ago' '+[%d/%b/%Y:%H:%M:%S')" '$4 > date {print $                   1}' "$LOG_FILE" | wc -l)
echo "Количество обращений за последние 180 дней: $last_180d"



