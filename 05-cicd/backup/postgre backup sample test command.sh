# 도커에서 테스트할 때는 도커 컨테이너 간의 통신을 위해 --link 옵션 필요
# postgres 라는 이름을 가진 컨테이너에 접속할 때 postgres 라는 이름으로 접속하겠다는 설정
docker run --link postgres:postgres -it 10.0.0.20:8082/backup  /bin/bash

docker run -p 5432:5432 --name postgres -e POSTGRES_PASSWORD=qwer1234 -d postgres
CREATE USER couser PASSWORD 'qwer1234' SUPERUSER;
CREATE DATABASE co OWNER couser;

# ubuntu 컨테이너에서 접속 테스트
psql -h postgres -U couser -d co

# 명령어 수행 결과 컨테이너의 로컬 경로에 저장됨
PGPASSWORD="qwer1234" pg_dump -U co -h postgres co > ./co.sql
