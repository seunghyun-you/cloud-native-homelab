# Hardware Specification

홈랩 환경 구축을 위한 하드웨어 선정 및 구성 내용입니다.

## 선정 기준

홈랩 환경 구축 시 고려한 요소들:

| 항목 | 요구사항 | 이유 |
|------|----------|------|
| **CPU** | 8코어 이상 (16스레드) | 다수의 VM 동시 운영 |
| **Memory** | 32GB 이상 | K8s 노드당 4GB 기준 8대 운영 |
| **Storage** | NVMe SSD 1TB | VM 디스크 I/O 성능 |
| **전력** | 저전력 (TDP 45W 이하) | 24시간 운영 시 전기료 |
| **소음** | 저소음 | 가정 내 설치 |
| **크기** | 소형 | 설치 공간 제약 |

## 선정 장비

### BEELINK SER8 (베어본)

```
┌─────────────────────────────────────────┐
│           BEELINK SER8 8745HS           │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │  AMD Ryzen 7 8745HS             │   │
│   │  8 Core / 16 Thread             │   │
│   │  Base 3.8GHz / Boost 4.9GHz     │   │
│   │  TDP: 35-54W                    │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌───────────────┐ ┌───────────────┐   │
│   │ DDR5-5600     │ │ NVMe M.2      │   │
│   │ 32GB (16x2)   │ │ 1TB SSD       │   │
│   └───────────────┘ └───────────────┘   │
│                                         │
│   Ports: 2.5GbE, USB4, HDMI 2.1        │
│   Size: 126 x 113 x 42mm               │
└─────────────────────────────────────────┘
```

### 상세 사양

| 구분 | 사양 | 비고 |
|------|------|------|
| **CPU** | AMD Ryzen 7 8745HS | Zen 4, 8C/16T |
| **Memory** | Micron Crucial DDR5-5600 32GB | 16GB x 2 (Dual Channel) |
| **Storage** | NVMe SSD 1TB | 기본 장착 |
| **Network** | 2.5 Gigabit Ethernet | Intel I226-V |
| **Graphics** | AMD Radeon 780M (iGPU) | HDMI 2.1 출력 |

## 운영체제 설치

### Ubuntu 24.04 LTS Desktop

기존 Windows를 제거하고 Ubuntu를 직접 설치했습니다.

**설치 방법:**
1. Rufus를 사용하여 Ubuntu 24.04 LTS 부팅 USB 생성
2. BIOS에서 Secure Boot 비활성화
3. USB 부팅 후 "Erase disk and install Ubuntu" 선택
4. 설치 완료 후 VirtualBox 설치

**Desktop 버전 선택 이유:**
- VirtualBox GUI 관리 편의성
- 원격 접속 시 VNC/RDP 활용 가능
- 모니터링 대시보드 직접 확인

### 설치 후 구성

```bash
# VirtualBox 설치
sudo apt update
sudo apt install virtualbox virtualbox-ext-pack -y

# Vagrant 설치
wget https://releases.hashicorp.com/vagrant/2.4.1/vagrant_2.4.1-1_amd64.deb
sudo dpkg -i vagrant_2.4.1-1_amd64.deb

# Vagrant 플러그인
vagrant plugin install vagrant-vbguest
```

## 비용 분석

### 초기 구매 비용

| 항목 | 가격 (KRW) |
|------|------------|
| BEELINK SER8 베어본 | ~500,000 |
| Micron DDR5-5600 32GB | ~120,000 |
| NVMe SSD 1TB (기본 포함) | - |
| **합계** | **~620,000** |

### 월 운영 비용 (예상)

| 항목 | 산출 | 비용 |
|------|------|------|
| 전기료 | 40W × 24h × 30일 = 28.8kWh | ~4,000원/월 |

### Cloud 대비 비용 비교

동일 사양 AWS EC2 인스턴스 비용 (서울 리전, On-Demand):

| 구성 | 인스턴스 타입 | 월 비용 (USD) |
|------|---------------|---------------|
| 2C/4GB × 7대 | t3.medium | ~$290 |
| 1C/1GB × 1대 | t3.micro | ~$7 |
| EBS 300GB | gp3 | ~$24 |
| **합계** | | **~$321/월** |

**결론**: 약 2개월 운영 시 홈랩 투자비용 회수

## 확장 가능성

### 현재 여유 리소스

```
CPU:    16 Thread 중 15 Thread 사용 → 1 Thread 여유
Memory: 32GB 중 29GB 할당 → 3GB 여유
Storage: 1TB 중 ~400GB 사용 → 600GB 여유
```

### 확장 옵션

1. **Memory 확장**: DDR5 64GB까지 지원 (32GB × 2)
2. **Storage 확장**: 추가 NVMe 슬롯 활용
3. **노드 추가**: 동일 미니 PC 추가 구매 후 클러스터 확장
