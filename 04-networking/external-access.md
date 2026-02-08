# External Access Architecture

홈랩 환경에 외부에서 안전하게 접근하기 위한 하이브리드 아키텍처입니다.

## 배경 및 요구사항

### 해결하고자 한 문제

| 문제                    | 설명                                                                 |
| ----------------------- | -------------------------------------------------------------------- |
| **보안 위험**           | 가정용 공유기(ipTIME)에서 22/80/443 포트 직접 오픈 시 보안 침해 위험 |
| **세부 보안 설정 한계** | 가정용 공유기의 방화벽/ACL 기능 제한                                 |
| **HTTPS 적용 불가**     | ipTIME 동적 도메인에 SSL 인증서 적용 불가                            |
| **어디서든 접근**       | 외부에서 홈랩 서비스(IDE, CI/CD, 모니터링)에 접근 필요               |

### 설계 목표

1. 홈 네트워크 직접 노출 없이 외부 접근 허용
2. HTTPS 적용으로 통신 암호화
3. 서비스별 도메인/포트 기반 라우팅
4. 비용 최소화 (무료 클라우드 리소스 활용)

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              External Access Flow                                │
└─────────────────────────────────────────────────────────────────────────────────┘

    User (Anywhere)
         │
         │ HTTPS Request
         │ *.container-wave.com
         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Oracle Cloud Infrastructure (OCI)                         │
│                              Free Tier VM                                        │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                                                                           │  │
│  │   ┌─────────────────────┐      ┌─────────────────────┐                   │  │
│  │   │   Nginx             │      │   OpenVPN Server    │                   │  │
│  │   │   Reverse Proxy     │      │                     │                   │  │
│  │   │   + SSL Termination │      │   UDP 1194          │                   │  │
│  │   │   (Let's Encrypt)   │      │                     │                   │  │
│  │   └──────────┬──────────┘      └──────────┬──────────┘                   │  │
│  │              │                            │                               │  │
│  │              └────────────┬───────────────┘                               │  │
│  │                           │ VPN Tunnel (192.168.200.0/24)                      │  │
│  │                           │                                               │  │
│  └───────────────────────────┼───────────────────────────────────────────────┘  │
│                              │                                                   │
│   Security Group Rules:      │                                                   │
│   - Inbound: TCP 443, 8080, 8081 (HTTPS)                                        │
│   - Inbound: UDP 1194 (OpenVPN)                                                 │
│   - Outbound: All allowed                                                        │
│                              │                                                   │
└──────────────────────────────┼──────────────────────────────────────────────────┘
                               │
                               │ VPN Tunnel
                               │ (Encrypted)
                               ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Home Network                                           │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │   ipTIME Router                                                           │  │
│  │   - No inbound ports exposed                                              │  │
│  │   - Outbound UDP 1194 only (VPN)                                          │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                              │                                                   │
│                              ▼                                                   │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │   Mini PC (OpenVPN Client)                                                │  │
│  │   VPN IP: 192.168.200.2                                                        │  │
│  │                                                                           │  │
│  │   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │  │
│  │   │ code-server │ │   ArgoCD    │ │   Jenkins   │ │   Nexus     │        │  │
│  │   │   :8443     │ │   :8080     │ │   :8080     │ │   :8081     │        │  │
│  │   └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘        │  │
│  │   ┌─────────────┐ ┌─────────────┐                                        │  │
│  │   │   Grafana   │ │ Sample App  │                                        │  │
│  │   │   :3000     │ │   :80/443   │                                        │  │
│  │   └─────────────┘ └─────────────┘                                        │  │
│  │                                                                           │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 구성 요소

### 1. OCI Free Tier VM

Oracle Cloud Infrastructure에서 제공하는 Always Free 리소스 활용:

| 항목        | 사양                   |
| ----------- | ---------------------- |
| **Shape**   | VM.Standard.E2.1.Micro |
| **vCPU**    | 1 OCPU                 |
| **Memory**  | 1 GB                   |
| **Storage** | 50 GB Boot Volume      |
| **Network** | Public IP (고정)       |
| **비용**    | 무료 (Always Free)     |

### 2. 도메인 및 DNS

| 항목           | 내용                        |
| -------------- | --------------------------- |
| **도메인**     | container-wave.com          |
| **등록기관**   | 가비아 (Gabia)              |
| **DNS 레코드** | A 레코드 → OCI VM Public IP |

**DNS 설정:**
```
container-wave.com.        A    <OCI_PUBLIC_IP>
www.container-wave.com.    A    <OCI_PUBLIC_IP>
vscode.container-wave.com. A    <OCI_PUBLIC_IP>
cicd.container-wave.com.   A    <OCI_PUBLIC_IP>
mgmt.container-wave.com.   A    <OCI_PUBLIC_IP>
```

### 3. SSL/TLS 인증서

Let's Encrypt를 활용한 무료 SSL 인증서:

| 항목         | 내용                     |
| ------------ | ------------------------ |
| **인증서**   | Let's Encrypt Wildcard   |
| **도메인**   | *.container-wave.com     |
| **갱신**     | Certbot 자동 갱신 (cron) |
| **유효기간** | 90일 (자동 갱신)         |

**인증서 발급:**
```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx -y

# 인증서 발급 (DNS 검증)
sudo certbot certonly --manual --preferred-challenges dns \
  -d "container-wave.com" \
  -d "*.container-wave.com"

# 자동 갱신 설정 확인
sudo certbot renew --dry-run
```

**자동 갱신 Cron:**
```bash
# /etc/cron.d/certbot
0 0,12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
```

### 4. OpenVPN 터널

OCI VM과 홈랩 Mini PC 간 암호화된 VPN 터널:

| 구성    | 역할           | VPN IP        |
| ------- | -------------- | ------------- |
| OCI VM  | OpenVPN Server | 192.168.200.1 |
| Mini PC | OpenVPN Client | 192.168.200.2 |

**보안 설정:**
- OCI Security Group: UDP 1194만 허용
- 홈 공유기: Outbound만 허용 (Inbound 차단)

### 5. Nginx Reverse Proxy

서비스별 도메인/포트 기반 라우팅:

| 외부 접근 URL                   | 내부 서비스        | 용도                  |
| ------------------------------- | ------------------ | --------------------- |
| `www.container-wave.com:443`    | 192.168.200.2:80   | Sample Application    |
| `vscode.container-wave.com:443` | 192.168.200.2:8443 | Code Server (Web IDE) |
| `cicd.container-wave.com:443`   | 192.168.200.2:8080 | ArgoCD                |
| `cicd.container-wave.com:8080`  | 192.168.200.2:8080 | Jenkins               |
| `cicd.container-wave.com:8081`  | 192.168.200.2:8081 | Nexus Repository      |
| `mgmt.container-wave.com:443`   | 192.168.200.2:3000 | Grafana               |

## 보안 설계

### 다층 보안 구조

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: OCI Security Group                                     │
│ - Whitelist 방식 (필요한 포트만 허용)                            │
│ - UDP 1194 (VPN), TCP 443/8080/8081 (HTTPS)                    │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: SSL/TLS Encryption                                     │
│ - Let's Encrypt 인증서                                          │
│ - TLS 1.2+ 강제                                                 │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: VPN Tunnel                                             │
│ - OpenVPN AES-256-GCM 암호화                                    │
│ - 인증서 기반 인증                                               │
├─────────────────────────────────────────────────────────────────┤
│ Layer 4: Home Network Isolation                                 │
│ - 인바운드 포트 없음                                             │
│ - VPN 아웃바운드만 허용                                          │
└─────────────────────────────────────────────────────────────────┘
```

### 직접 노출 vs VPN 터널 비교

| 항목           | 직접 노출        | VPN 터널 (현재 구성) |
| -------------- | ---------------- | -------------------- |
| 홈 IP 노출     | O                | X (OCI IP만 노출)    |
| 포트 스캔 대상 | 홈 네트워크      | OCI VM               |
| DDoS 영향      | 홈 네트워크 마비 | OCI에서 차단         |
| SSL 인증서     | 적용 불가        | Let's Encrypt 적용   |
| 세부 ACL       | 공유기 한계      | Security Group       |

## 비용 분석

### 월 운영 비용

| 항목                        | 비용                       |
| --------------------------- | -------------------------- |
| OCI VM                      | 무료 (Always Free)         |
| 도메인 (container-wave.com) | ~15,000원/년 (~1,250원/월) |
| SSL 인증서                  | 무료 (Let's Encrypt)       |
| **합계**                    | **~1,250원/월**            |

### 대안 비용 비교

| 방식              | 월 비용  | 비고              |
| ----------------- | -------- | ----------------- |
| **현재 구성**     | ~1,250원 | OCI Free + 도메인 |
| AWS ALB + ACM     | ~$20+    | ALB 시간당 과금   |
| Cloudflare Tunnel | 무료~$5  | 대역폭 제한       |
| ngrok Pro         | ~$10     | 커스텀 도메인     |

## 트래픽 흐름 예시

### 외부에서 Grafana 접근

```
1. User → https://mgmt.container-wave.com
         │
2.       └─► DNS → OCI Public IP
                   │
3.                 └─► OCI Nginx (SSL Termination)
                       │ proxy_pass http://192.168.200.2:3000
4.                     └─► VPN Tunnel
                           │
5.                         └─► Mini PC (192.168.200.2)
                               │
6.                             └─► Grafana (:3000)
                                   │
7.                                 └─► Response (역순)
```

## 관련 문서

- [04-networking/openvpn/](./openvpn/) - OpenVPN 상세 설정
- [04-networking/nginx/](./nginx/) - Nginx Reverse Proxy 설정
