# BUILD COMMAND: docker build -t postgres16:1 .
FROM postgres:16.5

# LOCALE 설정
RUN localedef -i ko_KR -c -f UTF-8 -A /usr/share/locale/locale.alias ko_KR.UTF-8
ENV LANG=ko_KR.utf8

# localtime 에 링크할 시간대를 링크.
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# 원하는 시간대 링크후 아래 수행시, /etc/timezone 파일변경됨.
RUN dpkg-reconfigure -f noninteractive tzdata

# postgresql.conf 파일 업로드
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]