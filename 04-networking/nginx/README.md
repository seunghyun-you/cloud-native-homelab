# Nginx Reverse Proxy

OCI VM에서 운영되는 Nginx 리버스 프록시 설정입니다.

## 개요

외부 HTTPS 요청을 SSL Termination 후 VPN 터널을 통해 홈랩 내부 서비스로 라우팅합니다.

## 아키텍처

```
External Request                    OCI VM (Nginx)                     HomeLab
─────────────────                  ─────────────────                  ─────────────

https://vscode.*:443  ──────────►  SSL Termination  ──────────────►  :8080 (code-server)
https://www.*:443     ──────────►  + Reverse Proxy  ──────────────►  :9000 (Ingress)
https://cicd.*:443    ──────────►       │           ──────────────►  :8443 (ArgoCD)
https://cicd.*:8080   ──────────►       │           ──────────────►  :18080 (Jenkins)
https://cicd.*:8081   ──────────►       │           ──────────────►  :18081 (Nexus)
https://mgmt.*:443    ──────────►       │           ──────────────►  :80 (Grafana)
                                        │
                                   Let's Encrypt
                                   Wildcard Cert
                                   *.container-wave.com
```

## 파일 구조

```
nginx/
├── README.md           # 본 문서
├── nginx.conf          # 리버스 프록시 설정 (sites-available)
└── certrenew.sh        # Let's Encrypt 자동 갱신 스크립트
```

## 설정 파일 설명

### nginx.conf

서브도메인 및 포트별 server 블록 구성:

| Server Block | Listen | Server Name               | Proxy Pass          |
| ------------ | ------ | ------------------------- | ------------------- |
| HTTP → HTTPS | 80     | _ (all)                   | 301 redirect        |
| Code Server  | 443    | vscode.container-wave.com | 192.168.200.2:8080  |
| Sample App   | 443    | www.container-wave.com    | 192.168.200.2:9000  |
| ArgoCD       | 443    | cicd.container-wave.com   | 192.168.200.2:8443  |
| Jenkins      | 8080   | cicd.container-wave.com   | 192.168.200.2:18080 |
| Nexus        | 8081   | cicd.container-wave.com   | 192.168.200.2:18081 |
| Grafana      | 443    | mgmt.container-wave.com   | 192.168.200.2:80    |

### 주요 설정 항목

**SSL/TLS 설정:**
```nginx
ssl_certificate "/etc/letsencrypt/live/container-wave.com/fullchain.pem";
ssl_certificate_key "/etc/letsencrypt/live/container-wave.com/privkey.pem";
```

**Proxy 헤더 설정:**
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

**WebSocket 지원 (Code Server, Grafana 등):**
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_http_version 1.1;
```

### certrenew.sh

Let's Encrypt 인증서 자동 갱신 스크립트:

```bash
#!/bin/bash
sudo systemctl stop nginx          # Nginx 중지 (포트 80 해제)
sudo certbot renew                  # 인증서 갱신
fuser -k 80/tcp                     # 포트 80 점유 프로세스 종료
sudo systemctl start nginx          # Nginx 재시작
```

**Cron 설정 (예시):**
```bash
# 매월 1일 03:00에 갱신 실행
0 3 1 * * /path/to/certrenew.sh >> /var/log/certbot-renew.log 2>&1
```

## 설치 및 설정

### 1. Nginx 설치

```bash
sudo apt update
sudo apt install nginx -y
```

### 2. 설정 파일 배포

```bash
# 설정 파일 복사
sudo cp nginx.conf /etc/nginx/sites-available/container-wave.conf

# 심볼릭 링크 생성
sudo ln -s /etc/nginx/sites-available/container-wave.conf /etc/nginx/sites-enabled/

# 기본 설정 제거
sudo rm /etc/nginx/sites-enabled/default

# 설정 검증
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

### 3. Let's Encrypt 인증서 발급

```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx -y

# 인증서 발급 (DNS 검증 - 와일드카드)
sudo certbot certonly --manual --preferred-challenges dns \
  -d "container-wave.com" \
  -d "*.container-wave.com"

# 또는 HTTP 검증 (단일 도메인)
sudo certbot --nginx -d container-wave.com
```

### 4. 자동 갱신 설정

```bash
# 스크립트 실행 권한
chmod +x certrenew.sh

# Cron 등록
sudo crontab -e
# 추가: 0 3 1 * * /home/ubuntu/certrenew.sh
```

## 방화벽 설정

OCI Security List / Security Group:

| Direction | Protocol | Port | Source    |
| --------- | -------- | ---- | --------- |
| Ingress   | TCP      | 80   | 0.0.0.0/0 |
| Ingress   | TCP      | 443  | 0.0.0.0/0 |
| Ingress   | TCP      | 8080 | 0.0.0.0/0 |
| Ingress   | TCP      | 8081 | 0.0.0.0/0 |

## 트러블슈팅

### 502 Bad Gateway

```bash
# VPN 연결 확인
ping 192.168.200.2

# 백엔드 서비스 상태 확인
curl -I http://192.168.200.2:8080
```

### SSL 인증서 만료

```bash
# 인증서 상태 확인
sudo certbot certificates

# 수동 갱신
sudo certbot renew --dry-run
```

## 관련 블로그 포스트

- [Nginx Reverse Proxy 설정](https://engineer-diarybook.tistory.com/entry/Nginx-Reverse-Proxy-%EC%84%A4%EC%A0%95-1)
- [Let's Encrypt 무료 인증서 생성 및 HTTPS 적용](https://engineer-diarybook.tistory.com/entry/Nginx-Lets-Encryption-%EB%AC%B4%EB%A3%8C-%EC%9D%B8%EC%A6%9D%EC%84%9C-%EC%83%9D%EC%84%B1-%EB%B0%8F-HTTPS-%EC%A0%81%EC%9A%A9)
