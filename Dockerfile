FROM ghcr.io/linuxserver/baseimage-alpine:3.14 as migration-bins

RUN \
  echo "**** install buid packages ****" && \
  apk add --no-cache \
    curl \
    git \
    go && \
  echo "**** build fs-repo-migrations ****" && \
  mkdir /bins && \
  IPFSMIG_VERSION=$(curl -sX GET "https://api.github.com/repos/ipfs/fs-repo-migrations/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]') && \
  git clone https://github.com/ipfs/fs-repo-migrations.git && \
  cd fs-repo-migrations && \
  git checkout ${IPFSMIG_VERSION} && \
  for BUILD in fs-repo-migrations fs-repo-9-to-10 fs-repo-10-to-11; do \
    cd ${BUILD} && \
    go build && \
    mv fs-repo-* /bins/ && \
    cd .. ; \
  done

FROM ghcr.io/linuxserver/baseimage-alpine:3.14 as ipfswebui

ARG IPFSWEB_VERSION

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache \
    alpine-sdk \
    git \
    nodejs \
    npm \
    python3-dev && \
  echo "**** build frontend ****" && \
  if [ -z ${IPFSWEB_VERSION+x} ]; then \
    IPFSWEB_VERSION=$(curl -sX GET "https://api.github.com/repos/ipfs/ipfs-webui/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  git clone https://github.com/ipfs/ipfs-webui.git && \
  cd ipfs-webui/ && \
  git checkout v2.13.0 && \
  npm install --production && \
  npm install typescript && \
  NODE_ENV=production \
    node node_modules/react-scripts/bin/react-scripts.js build
 
FROM ghcr.io/linuxserver/baseimage-alpine:3.14

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# environment
ENV IPFS_PATH=/config/ipfs

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    curl \
    logrotate \
    nginx \
    openssl && \
  apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    go-ipfs && \
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
COPY --from=migration-bins /bins /usr/bin
COPY --from=ipfswebui /ipfs-webui/build/ /var/www/html/

# ports and volumes
EXPOSE 80 443 4001 5001 8080
VOLUME ["/config"]
