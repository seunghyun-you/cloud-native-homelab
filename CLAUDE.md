# CLAUDE.md - 홈랩 포트폴리오 프로젝트 가이드

## 프로젝트 개요

미니 PC를 활용한 홈랩 환경 구성 포트폴리오입니다.
이직용 포트폴리오로, 실무 역량과 기술 스택을 체계적으로 정리합니다.

## 작성자 경력

- **총 경력**: 5년 6개월
- **Software Engineer (SRE, On-Premise)**: 1년
- **Cloud Engineer & Architect (AWS)**: 4년 6개월

## 기술 스택

### Container & Orchestration
- Kubernetes
- OCI (Container Registry)

### Infrastructure as Code
- Vagrant

### Networking
- Cilium (CNI)
- Nginx (Ingress/Reverse Proxy)
- OpenVPN

### Storage
- Cephadm (Ceph Cluster)
- NFS CSI Driver
- NetApp CSI Driver
- Ceph CSI Driver

### CI/CD
- ArgoCD (GitOps)
- Jenkins
- GitHub

### Observability
- Prometheus
- Grafana

### OS
- Ubuntu 24.04

## 디렉토리 구조

```
├── 01-infrastructure/     # 하드웨어 및 VM 프로비저닝
├── 02-kubernetes/         # K8s 클러스터 및 CNI 구성
├── 03-storage/            # 분산 스토리지 및 CSI 드라이버
├── 04-networking/         # 네트워크 서비스 (Ingress, VPN)
├── 05-cicd/               # CI/CD 파이프라인 구성
├── 06-observability/      # 모니터링 스택
└── docs/                  # 문서 및 트러블슈팅
```

## 작업 규칙

### 문서 작성
- 모든 문서는 한국어로 작성
- 마크다운 형식 사용
- 코드 블록에는 언어 명시

### 설정 파일
- YAML 파일은 주석으로 설명 추가
- 민감 정보(비밀번호, 토큰)는 `<PLACEHOLDER>` 형태로 마스킹

### 명명 규칙
- 디렉토리: kebab-case
- 파일명: kebab-case.md / kebab-case.yaml
- Kubernetes 리소스: kebab-case

## 우선순위

포트폴리오 작성 순서:
1. README.md (프로젝트 개요)
2. 01-infrastructure (기반 환경)
3. 02-kubernetes (핵심 플랫폼)
4. 03-storage (영구 스토리지)
5. 04-networking (네트워크 서비스)
6. 05-cicd (배포 자동화)
6. 06-observability (모니터링)
7. docs (트러블슈팅, 회고)

## 참고사항

- 이 포트폴리오는 실제 홈랩 환경 구축 경험을 문서화한 것입니다
- 각 섹션은 독립적으로 이해할 수 있도록 작성합니다
- 아키텍처 다이어그램은 Mermaid 또는 draw.io 사용
