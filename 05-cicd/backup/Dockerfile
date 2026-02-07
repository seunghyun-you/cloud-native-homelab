FROM postgres:16-alpine

# 필요한 도구 설치
RUN apk add --no-cache bash curl awscli

# 백업 스크립트 복사
COPY backup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/backup.sh