# 01. Infrastructure

미니 PC를 활용한 홈랩 인프라 기반 환경을 구성합니다.

## 개요

단일 미니 PC에서 Vagrant + VirtualBox를 활용하여 프로덕션 환경과 유사한 멀티 노드 클러스터를 구현했습니다.
OCI(Oracle Cloud Infrastructure)를 활용한 하이브리드 구성으로 외부에서 안전하게 접근할 수 있습니다.

## 전체 아키텍처 (Hybrid)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              External Access                                     │
│                                                                                  │
│   User (Anywhere)                                                                │
│        │                                                                         │
│        │ HTTPS (*.container-wave.com)                                            │
│        ▼                                                                         │
│   ┌─────────────────────────────────────┐                                        │
│   │     OCI VM (Free Tier)              │                                        │
│   │     - Nginx Reverse Proxy           │                                        │
│   │     - Let's Encrypt SSL/TLS         │                                        │
│   │     - OpenVPN Server                │                                        │
│   └──────────────────┬──────────────────┘                                        │
│                      │ VPN Tunnel (UDP 1194)                                     │
│                      │ 192.168.200.0/24                                          │
└──────────────────────┼──────────────────────────────────────────────────────────┘
                       │
┌──────────────────────┼──────────────────────────────────────────────────────────┐
│   Home Network       │                                                           │
│   (No Inbound Ports) │                                                           │
│                      ▼                                                           │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                 BEELINK SER8 (AMD Ryzen 7 8745HS)                        │   │
│   │                 16 Core / 32GB DDR5 / 1TB NVMe SSD                       │   │
│   │                 Ubuntu 24.04 LTS + OpenVPN Client                        │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## 홈랩 내부 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 BEELINK SER8 (AMD Ryzen 7 8745HS)                           │
│                 16 Core / 32GB DDR5 / 1TB NVMe SSD                          │
│                 Ubuntu 24.04 LTS Desktop                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                           VirtualBox + Vagrant                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─ Kubernetes Cluster ──────────────────────────────────────────────┐     │
│   │                                                                    │     │
│   │   Control Plane        Worker Nodes (Subnet1)                     │     │
│   │   ┌────────────┐      ┌────────────┐  ┌────────────┐              │     │
│   │   │ cilium-ctr │      │ cilium-w1  │  │ cilium-w2  │              │     │
│   │   │ 2C/4GB     │      │ 2C/4GB     │  │ 2C/4GB     │              │     │
│   │   │ .10.100    │      │ .10.101    │  │ .10.102    │              │     │
│   │   └────────────┘      └────────────┘  └────────────┘              │     │
│   │         │                    │              │                      │     │
│   │         │    192.168.10.0/24 (Subnet1)      │                      │     │
│   │         └────────────┬───────┴──────────────┘                      │     │
│   │                      │                                             │     │
│   │               ┌──────┴──────┐                                      │     │
│   │               │  cilium-r   │  Router                              │     │
│   │               │  1C/1GB     │  .10.200 ↔ .20.200                   │     │
│   │               └──────┬──────┘                                      │     │
│   │                      │                                             │     │
│   │         ┌────────────┴────────────┐                                │     │
│   │         │    192.168.20.0/24 (Subnet2)                             │     │
│   │         │                         │                                │     │
│   │   ┌─────┴──────┐                                                   │     │
│   │   │ cilium-w3  │  Worker Node (Subnet2)                           │     │
│   │   │ 2C/4GB     │                                                   │     │
│   │   │ .20.100    │                                                   │     │
│   │   └────────────┘                                                   │     │
│   │                                                                    │     │
│   └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│   ┌─ Ceph Storage Cluster ────────────────────────────────────────────┐     │
│   │   192.168.50.0/24 (Public) / 192.168.60.0/24 (Cluster)            │     │
│   │                                                                    │     │
│   │   ┌────────────┐  ┌────────────┐  ┌────────────┐                  │     │
│   │   │  ceph-01   │  │  ceph-02   │  │  ceph-03   │                  │     │
│   │   │ 2C/4GB     │  │ 2C/4GB     │  │ 2C/4GB     │                  │     │
│   │   │ +100GB OSD │  │ +100GB OSD │  │ +100GB OSD │                  │     │
│   │   └────────────┘  └────────────┘  └────────────┘                  │     │
│   │                                                                    │     │
│   └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 리소스 할당

| 노드 | 역할 | vCPU | Memory | Storage | Network |
|------|------|------|--------|---------|---------|
| cilium-ctr | K8s Control Plane | 2 | 4GB | - | 192.168.10.100 |
| cilium-w1 | K8s Worker | 2 | 4GB | - | 192.168.10.101 |
| cilium-w2 | K8s Worker | 2 | 4GB | - | 192.168.10.102 |
| cilium-w3 | K8s Worker (Subnet2) | 2 | 4GB | - | 192.168.20.100 |
| cilium-r | Router | 1 | 1GB | - | .10.200 / .20.200 |
| ceph-01 | Ceph OSD | 2 | 4GB | 100GB | 192.168.50.201 |
| ceph-02 | Ceph OSD | 2 | 4GB | 100GB | 192.168.50.202 |
| ceph-03 | Ceph OSD | 2 | 4GB | 100GB | 192.168.50.203 |
| **합계** | | **15** | **29GB** | **300GB** | |

## 핵심 설계 포인트

### 1. 하이브리드 아키텍처 (On-Premise + Cloud)
- OCI Free Tier를 활용한 외부 접근 게이트웨이
- OpenVPN 터널로 홈 네트워크 직접 노출 없이 안전한 접근
- Let's Encrypt SSL/TLS로 HTTPS 통신 암호화

### 2. Multi-Subnet 네트워크
- 실무 환경과 유사한 네트워크 분리 구현
- Router 노드를 통한 서브넷 간 통신
- Cilium Native Routing 모드 적용

### 3. 스토리지 네트워크 분리
- Public Network (192.168.50.x): 클라이언트 접근
- Cluster Network (192.168.60.x): OSD 간 복제 트래픽

### 4. IaC 기반 자동화
- `vagrant up` 단일 명령으로 전체 환경 구성
- 재현 가능한 인프라 환경

## 외부 서비스 접근

| 서비스 | URL | 용도 |
|--------|-----|------|
| Sample App | https://www.container-wave.com | 샘플 애플리케이션 |
| Code Server | https://vscode.container-wave.com | Web IDE |
| ArgoCD | https://cicd.container-wave.com | GitOps 대시보드 |
| Jenkins | https://cicd.container-wave.com:8080 | CI 파이프라인 |
| Nexus | https://cicd.container-wave.com:8081 | Artifact Repository |
| Grafana | https://mgmt.container-wave.com | 모니터링 대시보드 |

## 문서 구성

- [hardware-spec.md](./hardware-spec.md) - 하드웨어 사양 및 선정 기준
- [network-topology.md](./network-topology.md) - 네트워크 토폴로지 상세
- [external-access.md](./external-access.md) - 외부 접근 아키텍처 (OCI + VPN)
- [vagrant/README.md](./vagrant/README.md) - Vagrant 프로비저닝 가이드

## 사용된 기술

- **가상화**: VirtualBox 7.x
- **프로비저닝**: Vagrant
- **Base Image**: bento/ubuntu-24.04
- **Container Runtime**: containerd 1.7.27
- **Cloud**: Oracle Cloud Infrastructure (OCI) Free Tier
- **VPN**: OpenVPN
- **Reverse Proxy**: Nginx
- **SSL/TLS**: Let's Encrypt (Certbot)
