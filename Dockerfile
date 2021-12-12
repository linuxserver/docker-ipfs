 FROM ghcr.io/linuxserver/baseimage-alpine:3.14

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="IPFS-LINK_GW version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="gxnt-samir"

# environment
ENV IPFS_PATH=/config/ipfs

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    curl \
    logrotate \
    nginx \
    openssl && \
  apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community && \
  wget https://github.com/ipfs/go-ipfs/releases/download/v0.11.0/go-ipfs_v0.11.0_linux-arm64.tar.gz && \
  tar -zxvf go-ipfs_v0.11.0_linux-arm64.tar.gz && \
  cd go-ipfs/ && mv ipfs /bin/ipfs && cd .. && rm -r go-ipfs && rm go-ipfs_v0.11.0_linux-arm64.tar.gz && \
  mkdir -p /var/www/html && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" /etc/logrotate.conf && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/periodic/daily/logrotate && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# copy files
COPY root/ /

# ports and volumes
EXPOSE 80 443 4001 5001 8080
VOLUME ["/config"]

#docker build . -t ipfs-local