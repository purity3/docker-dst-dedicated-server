#!/bin/bash
set -Eeuo pipefail

# set -e error handler.
on_error() {
    echo >&2 "Error on line ${1}${3+: ${3}}; RET ${2}."
    exit "$2"
}

trap 'on_error ${LINENO} $?' ERR 2>/dev/null || true # some shells don't have ERR trap.

if [ "$1" == "launchDST" ] || [ "$1" == "supervisord" ]; then

    #当系统未设置存档时，默认创建配置文件
    updateTemp

    # 更新游戏服务器
    updateServer

    # 更新游戏模组，一般需要跑两次才完全下载完
    updateMods

    # 重建supervisor的相关记录
    rm -f /var/run/supervisor.sock
    touch /var/run/supervisor.sock
fi

exec "$@"
