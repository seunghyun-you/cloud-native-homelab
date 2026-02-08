# OpenVPN Configuration

OCI VM과 홈랩 Mini PC 간의 VPN 터널 구성입니다.

## 개요

홈 네트워크를 외부에 직접 노출하지 않고, OCI VM을 통해 안전하게 접근할 수 있도록 VPN 터널을 구성합니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   OCI VM (OpenVPN Server)              Home Network (OpenVPN Client)        │
│   ─────────────────────────            ──────────────────────────────       │
│                                                                             │
│   ┌─────────────────────┐              ┌─────────────────────┐              │
│   │  Public IP          │              │  Private IP         │              │
│   │  (Internet facing)  │              │  (Behind NAT)       │              │
│   │                     │   Outbound   │                     │              │
│   │  tun0: 192.168.200.1│◄─────────────│  tun0: 192.168.200.2│              │
│   │                     │   UDP 1194   │                     │              │
│   │  OpenVPN Server     │              │  OpenVPN Client     │              │
│   └─────────────────────┘              └─────────────────────┘              │
│              │                                    │                         │
│              │         VPN Tunnel                 │                         │
│              │      192.168.200.0/24              │                         │
│              │                                    │                         │
│              ▼                                    ▼                         │
│   ┌─────────────────────┐              ┌─────────────────────┐              │
│   │  Nginx              │              │  K8s Services       │              │
│   │  Reverse Proxy      │──────────────│  - code-server      │              │
│   │                     │  proxy_pass  │  - ArgoCD           │              │
│   │                     │              │  - Jenkins          │              │
│   └─────────────────────┘              │  - Nexus            │              │
│                                        │  - Grafana          │              │
│                                        └─────────────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 파일 구조

```
openvpn/
├── README.md       # 본 문서
├── server.conf     # OCI VM 서버 설정
└── client.conf     # Mini PC 클라이언트 설정
```

## 네트워크 구성

| 항목       | 값               |
| ---------- | ---------------- |
| VPN Subnet | 192.168.200.0/24 |
| Server IP  | 192.168.200.1    |
| Client IP  | 192.168.200.2    |
| Protocol   | UDP              |
| Port       | 1194             |
| Cipher     | AES-256-GCM      |

## 설정 파일 설명

### server.conf (OCI VM)

**핵심 설정:**

```conf
# 프로토콜 및 포트
port 1194
proto udp
dev tun

# VPN 서브넷 설정
server 192.168.200.0 255.255.255.0
topology subnet

# 암호화
data-ciphers AES-256-GCM:AES-128-GCM:?CHACHA20-POLY1305:AES-256-CBC
tls-auth ta.key 0

# 인증서 경로
ca ca.crt
cert issued/openvpn.container-wave.com.crt
key private/openvpn.container-wave.com.key
dh dh.pem

# 클라이언트 간 통신 허용
client-to-client

# DNS 설정
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# 연결 유지
keepalive 10 120

# 로그
log /var/log/openvpn/openvpn.log
status /var/log/openvpn/openvpn-status.log
```

### client.conf (Mini PC)

**핵심 설정:**

```conf
client
dev tun
proto udp

# 서버 주소 (OCI Public IP)
remote <OCI_PUBLIC_IP> 1194

# 인증서
ca ca.crt
cert <CLIENT_NAME>.crt
key <CLIENT_NAME>.key
tls-auth ta.key 1

# 옵션
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo yes
verb 3
```

## 설치 및 설정

### 1. 서버 설정 (OCI VM)

```bash
# OpenVPN 설치
sudo apt update
sudo apt install openvpn easy-rsa -y

# Easy-RSA 초기화
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# PKI 초기화 및 인증서 생성
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey secret ta.key

# 설정 파일 배포
sudo cp server.conf /etc/openvpn/server/
sudo cp -r pki/* /etc/openvpn/server/

# 서비스 시작
sudo systemctl enable openvpn-server@server
sudo systemctl start openvpn-server@server
```

### 2. 클라이언트 인증서 생성

```bash
# 클라이언트 인증서 생성 (서버에서)
cd ~/openvpn-ca
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# 클라이언트에 전달할 파일
# - ca.crt
# - client1.crt
# - client1.key
# - ta.key
```

### 3. 클라이언트 설정 (Mini PC)

```bash
# OpenVPN 설치
sudo apt install openvpn -y

# 설정 파일 및 인증서 배포
sudo cp client.conf /etc/openvpn/client/
sudo cp ca.crt client1.crt client1.key ta.key /etc/openvpn/client/

# 서비스 시작
sudo systemctl enable openvpn-client@client
sudo systemctl start openvpn-client@client
```

## 방화벽 설정

### OCI Security List

| Direction | Protocol | Port | Source    |
| --------- | -------- | ---- | --------- |
| Ingress   | UDP      | 1194 | 0.0.0.0/0 |

### OCI VM (iptables)

```bash
# IP Forwarding 활성화
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# NAT 설정 (필요시)
sudo iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o ens3 -j MASQUERADE
```

## 연결 확인

### 서버에서 확인

```bash
# 서비스 상태
sudo systemctl status openvpn-server@server

# 연결된 클라이언트 확인
cat /var/log/openvpn/openvpn-status.log

# tun 인터페이스 확인
ip addr show tun0
```

### 클라이언트에서 확인

```bash
# 서비스 상태
sudo systemctl status openvpn-client@client

# VPN IP 확인
ip addr show tun0

# 서버 연결 테스트
ping 192.168.200.1
```

## 트러블슈팅

### 연결 실패

```bash
# 클라이언트 로그 확인
sudo journalctl -u openvpn-client@client -f

# 서버 로그 확인
sudo tail -f /var/log/openvpn/openvpn.log

# 포트 확인
sudo netstat -ulnp | grep 1194
```

### TLS 핸드셰이크 실패

- ta.key 파일이 서버/클라이언트에 동일한지 확인
- 서버: `tls-auth ta.key 0`
- 클라이언트: `tls-auth ta.key 1`

### 클라이언트 IP 할당 안됨

```bash
# 서버 설정 확인
grep "server " /etc/openvpn/server/server.conf

# IP 풀 확인
cat /var/log/openvpn/ipp.txt
```

## 보안 고려사항

1. **인증서 관리**: 클라이언트별 개별 인증서 발급
2. **키 보호**: private key 파일 권한 600 설정
3. **로그 모니터링**: 비정상 접속 시도 감지
4. **정기 갱신**: 인증서 만료 전 갱신
