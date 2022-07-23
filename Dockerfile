FROM debian:latest

LABEL maintainer="purity3 <qizhi2design@gmail.com>"

# Set build arguments.
ARG TZ=Asia/Shanghai
ARG LANG=C.UTF-8
ARG LC_ALL=C.UTF-8
ARG DST_USER=dst
ARG DST_USER_DATA_PATH=/data
ARG DST_SERVER_PATH=/opt/dstserver
ARG DST_TEMP_PATH=/opt/dst_template
ARG DST_TEMP_CLUSTER=IslandAdventure
ARG STEAMCMD_PATH=/opt/steamcmd/steamcmd.sh
ARG STEAMCMD_DOWNLOAD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

# Set default environment.
ENV TZ ${TZ}
ENV LANG ${LANG}
ENV LC_ALL ${LC_ALL}
ENV DST_USER ${DST_USER}
ENV DST_SERVER_PATH ${DST_SERVER_PATH}
ENV DST_TEMP_PATH ${DST_TEMP_PATH}
ENV DST_TEMP_CLUSTER ${DST_TEMP_CLUSTER}
ENV DST_USER_DATA_PATH ${DST_USER_DATA_PATH}
ENV STEAMCMD_PATH ${STEAMCMD_PATH}
ENV DEBIAN_FRONTEND noninteractive

# Change USTC Source and Set TIMEZONE
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install required packages
RUN set -x \
    && dpkg --add-architecture i386 \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates lib32stdc++6 libcurl3-gnutls:i386 libcurl3-gnutls wget tar supervisor \
    && (apt-get install -y --no-install-recommends --no-install-suggests lib32gcc-s1 \
    || apt-get install -y --no-install-recommends --no-install-suggests lib32gcc1) \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install steamcmd only if steamcmd doesn't exist
RUN test -e "${STEAMCMD_PATH}" && echo "Steamcmd detected" \
    || ( \
    echo "Installing steamcmd" \
    && wget "${STEAMCMD_DOWNLOAD_URL}" -O /tmp/steamcmd.tar.gz \
    && mkdir "/opt/steamcmd" \
    && tar -xvzf /tmp/steamcmd.tar.gz -C /opt/steamcmd \
    && rm -rf /tmp/* )

# Create data directory
RUN mkdir -p "${DST_USER_DATA_PATH}" \
    && ( groupadd "${DST_USER}" || true ) \
    && ( useradd -g "${DST_USER}" -d "${DST_USER_DATA_PATH}" "${DST_USER}" || true ) \
    && chown -R "${DST_USER}:${DST_USER}" "${DST_USER_DATA_PATH}"

# Install helper tools
COPY supervisor /etc/supervisor/
COPY commands /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Install Don't Starve Together Server
RUN mkdir -p "${DST_SERVER_PATH}" \
    && chown -R "${DST_USER}:${DST_USER}" "${DST_SERVER_PATH}" \
    && updateServer \
    && rm -rf /root/Steam /root/.steam

# Install default config
RUN mkdir -p "${DST_TEMP_PATH}"
COPY configs "${DST_TEMP_PATH}"
RUN chown -R "${DST_USER}:${DST_USER}" "${DST_TEMP_PATH}"

VOLUME ["${DST_USER_DATA_PATH}"]
EXPOSE 10999-11000/udp 12346-12347/udp
ENTRYPOINT [ "entrypoint.sh" ]
CMD ["supervisord", "-c", "/etc/supervisor/supervisor.conf", "-n"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 CMD [ "healthcheck.sh" ]