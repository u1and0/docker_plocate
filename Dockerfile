# CRON_CYCLE で指定したサイクルでupdatedbを定期実行し、
# locate (plocate) コマンドの実行を待ち受ける
#
# Usage:
#
# 1. Create database
# docker run --name app -t --rm \
#   -v /mnt:/mnt \
#   -e TZ='Asia/Tokyo' \
#   -e UPDATEDB_PATH=/mnt \        # default /
#   -e OPTION=--verbose \
#   -e cron_cycle="*/2 * * * *" \  # default @midnight
#   u1and0/updatedb
#
# 2. Search words
# $ docker exec -t locate OPTION... PATTERN...

FROM archlinux:base-devel
RUN pacman-key --init &&\
    pacman-key --populate archlinux
RUN pacman -Syu --noconfirm plocate tzdata cronie &&\
    : "Clear cache" &&\
    pacman -Qtdq | xargs -r pacman --noconfirm -Rcns

ENV UPDATEDB_PATH="/" \
    CRON_CYCLE="@midnight" \
    OPTION=""
    # same as CRON_CYCLE="0 0 * * *"
    # cron job execute at every midnight 24:00

CMD : "Write crontab" &&\
    echo "${CRON_CYCLE} updatedb -U ${UPDATEDB_PATH} ${OPTION}" | crontab - &&\
    : "Execute updatedb at first time" &&\
    updatedb -U ${UPDATEDB_PATH} ${OPTION} &&\
    : "Up cron daemon" &&\
    crond &&\
    : "Wait for some command (NOT exit container)" &&\
    tail -f /dev/null

LABEL maintainer="u1and0 <e01.ando60@gmail.com>"\
      description="Make database regularly by `updatedb` & `cron` , and search any path by `plocate`"\
      version="u1and0/plocate:v0.1.0"
