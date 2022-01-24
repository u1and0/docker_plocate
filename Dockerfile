# n時間ごとにupdatedbによってディレクトリデータベースを更新する
# app(このファイルで作成したイメージによるコンテナ)はtail -fでcrondの結果を標準出力に出力し続ける
#
# Usage:
# 1. Create database
# docker run --name app -t --rm \
#   -v /mnt:/mnt \
#   -e TZ='Asia/Tokyo' \
#   -e UPDATEDB_PATH=/mnt \
#   -e OPTION=--verbose \
#   -e cron_cycle="*/2 * * * *" \
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


# locate, updatedbコマンドを使用可能にする
# tzdataは環境変数ENVを変えるとUTCから変更される
# ex) docker run -d -e TZ='Asia/Tokyo' u1and0/updatedb

# build時に決定してしまう変数
# run時とbuild時に合わせるため、CMDで実行する
# ARG UPDATEDB_PATH="/"
# RUN echo "* * * * * updatedb -U ${UPDATEDB_PATH}" | crontab -

# ARG TASK="/etc/crontabs/root"
# RUN echo "SHELL=/bin/sh" > $TASK &&\
#     echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin" >> $TASK &&\
#     echo "* * * * * updatedb -U /work" >> $TASK

# ${UPDATEDB_PATH}以下のディレクトリを定期的にデータベース化
# 指定しない場合${UPDATEDB_PATH}のデフォルトは/

# /var/lib/mlocateディレクトリに${OUTPUT}で指定したファイル名のデータベースを作成する
# 指定しない場合${OUTPUT}のデフォルトはmlocate.db

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
# CMD ["crond", "&&", "tail", "-f", "/dev/null"]
# CMD ["updatedb","-U", "/work", "&&", "crond", "&&", "tail", "-f"]

LABEL maintainer="u1and0 <e01.ando60@gmail.com>"\
      description="make database regularly by `updatedb` command"\
      version="u1and0/plocate:v0.1.0"
