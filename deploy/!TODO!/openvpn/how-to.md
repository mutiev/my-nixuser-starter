Ниже приведена **полная инструкция** по развёртыванию OpenVPN-сервера на **Debian** с использованием **IPv4**-адреса сервера (белый IP) и подключением клиентов (телефон, ноутбук, компьютер) по протоколу **UDP**. При желании можно переключиться на **TCP**, заменив `proto udp` на `proto tcp`.

---

## 1. Установка и начальная настройка

1. **Обновите индекс пакетов и установите нужные пакеты**:

   ```bash
   sudo apt update
   sudo apt install openvpn easy-rsa
   ```

2. **Создайте каталог для корневого сертификата**:

   ```bash
   make-cadir ~/openvpn-ca
   ```

   Перейдите в него:

   ```bash
   cd ~/openvpn-ca
   ```

3. **Откройте файл `vars`** (например, через `nano` или `mcedit`):

   ```bash
   nano vars
   ```

   В конце файла добавьте (или измените) строки, указав ваши данные:

   ```bash
   export KEY_COUNTRY="RU"
   export KEY_PROVINCE="Moscow"
   export KEY_CITY="Moscow"
   export KEY_ORG="MyOrganization"
   export KEY_EMAIL="admin@example.com"
   export KEY_OU="MyOrganizationalUnit"
   export KEY_NAME="server"
   ```

   Сохраните файл.

---

## 2. Генерация сертификатов и ключей

1. **Инициализируйте PKI** (Public Key Infrastructure):

   ```bash
   ./easyrsa init-pki
   ```

2. **Создайте корневой сертификат (CA)**:

   ```bash
   ./easyrsa build-ca
   ```

   Вас попросят придумать пароль для сертификата CA, а также подтверждать ряд данных.

3. **Создайте запрос на сертификат для сервера**:

   ```bash
   ./easyrsa gen-req server nopass
   ```

   В результате будет сгенерирован приватный ключ сервера `server.key` и запрос на подпись `server.req`.

4. **Подпишите сертификат сервера**:

   ```bash
   ./easyrsa sign-req server server
   ```

   Нужно будет ввести `yes` для подтверждения, а затем пароль CA.

5. **Сгенерируйте параметры Диффи-Хеллмана** (DH):

   ```bash
   openssl dhparam -out dh2048.pem 2048
   ```

   (Это может занять некоторое время.)

6. **Создайте ключ HMAC (tls-auth)**:

   ```bash
   openvpn --genkey --secret ta.key
   ```

7. **Создайте ключ и сертификат для клиента** (например, `client1`):

   ```bash
   ./easyrsa build-client-full client1 nopass
   ```

---

## 3. Копирование сертификатов и ключей

Скопируйте необходимые файлы в директории OpenVPN:

```bash
# Серверные файлы:
cp pki/ca.crt /etc/openvpn/server/
cp pki/issued/server.crt /etc/openvpn/server/
cp pki/private/server.key /etc/openvpn/server/
cp dh2048.pem /etc/openvpn/server/
cp ta.key /etc/openvpn/server/

# Клиентские файлы:
cp pki/ca.crt /etc/openvpn/client/
cp pki/issued/client1.crt /etc/openvpn/client/
cp pki/private/client1.key /etc/openvpn/client/
cp ta.key /etc/openvpn/client/
```

---

## 4. Настройка сервера OpenVPN (IPv4)

Создайте (или отредактируйте) конфигурационный файл `/etc/openvpn/server.conf`:

```ini
# Порт и протокол
port 1194
proto udp
dev tun
tls-auth /etc/openvpn/server/ta.key 0

# Сертификаты и ключи
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh2048.pem

# Внутренняя IPv4-подсеть для клиентов
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"

# DNS-серверы
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Разрешить подключение нескольких клиентов с одним сертификатом
duplicate-cn

# Параметры шифрования
cipher AES-256-CBC
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
auth SHA512
auth-nocache

# Прочие настройки
keepalive 20 60
persist-key
persist-tun
compress lz4
daemon

# Лог
log-append /var/log/openvpn.log
verb 3
```

Сохраните файл.

---

## 5. Разрешить форвардинг IPv4 и настроить iptables

1. **Включите IPv4 форвардинг**:

   ```bash
   nano /etc/sysctl.conf
   ```

   Найдите строку:

   ```
   #net.ipv4.ip_forward=1
   ```

   Раскомментируйте (уберите `#`):

   ```
   net.ipv4.ip_forward=1
   ```

   Сохраните и примените:

   ```bash
   sysctl -p
   ```

2. **Настройка iptables** (если хотите, чтобы трафик клиентов ходил через сервер в интернет):

   ```bash
   # Разрешить входящие соединения для OpenVPN
   iptables -A INPUT -p udp --dport 1194 -j ACCEPT

   # Разрешить форвардинг подсети 10.8.0.0/24
   iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
   iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT

   # MASQUERADE трафика VPN-клиентов при выходе в интернет через eth0 (или другой интерфейс)
   iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
   ```

   Сохраните правила (если установлен `iptables-persistent`):

   ```bash
   iptables-save > /etc/iptables/rules.v4
   ```

---

## 6. Запуск и проверка

1. **Запустите сервер OpenVPN**:

   ```bash
   systemctl start openvpn@server
   ```
2. **Посмотрите статус**:

   ```bash
   systemctl status openvpn@server
   ```

   Если всё хорошо, увидите строку `active (running)`.
3. **Проверьте наличие туннельного интерфейса**:

   ```bash
   ip addr show tun0
   ```

   Пример:

   ```
   6: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> ...
       inet 10.8.0.1 peer 10.8.0.2/32 scope global tun0
       ...
   ```
4. **Включите автозапуск**:

   ```bash
   systemctl enable openvpn@server
   ```

---

## 7. Создание клиентской конфигурации

Перейдите в `/etc/openvpn/client/` и создайте базовый конфиг `base.conf` (или `base.ovpn`):

```ini
client
dev tun
proto udp
remote <ВНЕШНИЙ_IP_СЕРВЕРА> 1194

tls-auth ta.key 1

ca ca.crt
cert client1.crt
key client1.key

cipher AES-256-CBC
auth SHA512
auth-nocache
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256

resolv-retry infinite
compress lz4
nobind
persist-key
persist-tun
mute-replay-warnings
verb 3
```

Обратите внимание на строку `remote <ВНЕШНИЙ_IP_СЕРВЕРА> 1194` — вставьте **белый IPv4-адрес** вашего сервера.

---

### 7.1 Скрипт для встраивания ключей в `.ovpn`

Создайте скрипт `mkconfig.sh` в `/etc/openvpn/client/`:

```bash
#!/bin/bash

KEYS=/etc/openvpn/client/
OUTPUT=/etc/openvpn/client/
CONFIG=/etc/openvpn/client/base.conf

cat ${CONFIG} \
    <(echo -e '\n<ca>') \
    ${KEYS}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEYS}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEYS}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEYS}/ta.key \
    <(echo -e '</tls-auth>') \
    <(echo -e '\nkey-direction 1') \
    > ${OUTPUT}/${1}.ovpn
```

Сделайте его исполняемым:

```bash
chmod +x mkconfig.sh
```

---

### 7.2 Генерация `.ovpn` для клиента

```bash
cd /etc/openvpn/client/
./mkconfig.sh client1
```

В результате появится файл `client1.ovpn`, который содержит все ключи, сертификаты и настройки. Этот `.ovpn` файл нужно скопировать на клиент (телефон, ноутбук, компьютер).

---

## 8. Подключение клиента

1. **Скопируйте `client1.ovpn`** на клиентское устройство (через SCP, SFTP и т.д.).
2. **Импортируйте** файл в OpenVPN клиент (Tunnelblick, OpenVPN Connect, etc.).
3. **Подключитесь** к серверу.
   При успешном подключении ваш трафик пойдёт через VPN, а IP-адрес сменится на адрес вашего сервера.

---

## 9. Тестирование

1. **Проверка IP**:
   Откройте [https://ifconfig.co](https://ifconfig.co) или [https://2ip.ru/](https://2ip.ru/), чтобы убедиться, что ваш внешний IP совпадает с IP сервера.
2. **Ping внутреннего адреса**:
   Попробуйте `ping 10.8.0.1` (адрес сервера внутри VPN) с клиента.
3. **Маршрутизация**:
   Убедитесь, что маршрут по умолчанию (`0.0.0.0/1` и `128.0.0.0/1`) уходит в VPN.

---

## Итоги

Теперь у вас есть рабочий OpenVPN-сервер на Debian, с использованием **белого IPv4**-адреса для внешнего подключения. Клиенты получают подсеть `10.8.0.0/24` и могут безопасно передавать трафик через сервер.

Если потребуется что-то донастроить (SSH только через VPN, или ограничить доступ по портам), можно добавить соответствующие правила в **iptables**.

Если возникнут проблемы, обратитесь к логам:

* **Сервер**: `journalctl -xeu openvpn@server`, `/var/log/openvpn.log`
* **Клиент**: запустить `openvpn --config client1.ovpn --verb 4` и смотреть вывод.

Удачи в настройке!
