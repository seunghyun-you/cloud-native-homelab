# 01. Infrastructure

단일 미니 PC에서 Vagrant + VirtualBox를 활용하여 프로덕션 환경과 유사한 멀티 노드 클러스터를 구현했습니다.
OCI(Oracle Cloud Infrastructure)를 활용한 하이브리드 구성으로 외부에서 안전하게 접근할 수 있습니다.

## 전체 아키텍처 (Hybrid)

![alt text](../00-images/infrastructure-architecture.png)

## 리소스 스펙

### 1. Hardware

BEELINK SER8 (베어본) Mini PC 사양 정보

| 구분         | 사양                          | 비고                    |
| ------------ | ----------------------------- | ----------------------- |
| **CPU**      | AMD Ryzen 7 8745HS            | Zen 4, 8C/16T           |
| **Memory**   | Micron Crucial DDR5-5600 32GB | 16GB x 2 (Dual Channel) |
| **Storage**  | NVMe SSD 1TB                  |                         |
| **Graphics** | AMD Radeon 780M (iGPU)        |                         |


### 2. Virtual Machine

| 노드       | 역할              | vCPU   | Memory   | Storage   |
| ---------- | ----------------- | ------ | -------- | --------- |
| oracle-vm  | Reverse Proxy     | 1      | 1GB      | 50GB      |
| cilium-ctr | K8s Control Plane | 2      | 4GB      | 50GB      |
| cilium-w1  | K8s Worker Node   | 2      | 4GB      | 50GB      |
| cilium-w2  | K8s Worker Node   | 2      | 4GB      | 50GB      |
| cilium-w3  | K8s Worker Node   | 2      | 4GB      | 50GB      |
| cilium-r   | Router            | 1      | 1GB      | 50GB      |
| ceph-01    | Ceph OSD          | 2      | 4GB      | 100GB     |
| ceph-02    | Ceph OSD          | 2      | 4GB      | 100GB     |
| ceph-03    | Ceph OSD          | 2      | 4GB      | 100GB     |
| **합계**   |                   | **15** | **29GB** | **300GB** |

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

| 서비스      | URL                                  | 용도                |
| ----------- | ------------------------------------ | ------------------- |
| Sample App  | https://www.container-wave.com       | 샘플 애플리케이션   |
| Code Server | https://vscode.container-wave.com    | Web IDE             |
| ArgoCD      | https://cicd.container-wave.com      | GitOps 대시보드     |
| Jenkins     | https://cicd.container-wave.com:8080 | CI 파이프라인       |
| Nexus       | https://cicd.container-wave.com:8081 | Artifact Repository |
| Grafana     | https://mgmt.container-wave.com      | 모니터링 대시보드   |

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
