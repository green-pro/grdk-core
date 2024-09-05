FROM alpine:3.9

ARG MYDUMPER_VERSION=0.9.5
ARG AWSCLI_VERSION=1.16.161

ENV PACKAGES="mysql-client" \
    LIB_PACKAGES="glib-dev mysql-dev zlib-dev pcre-dev libressl-dev ca-certificates openssl python2 bash curl rsync" \
    BUILD_PACKAGES="cmake build-base py2-pip" \
    BUILD_PATH="/tmp/mydumper-src/"

RUN apk --no-cache add \
          $PACKAGES \
          $BUILD_PACKAGES \
          $LIB_PACKAGES && \
    mkdir -p $BUILD_PATH && \
    cd $BUILD_PATH && \
    wget "https://github.com/maxbube/mydumper/archive/v$MYDUMPER_VERSION.tar.gz" -O mydumper.tar.gz && \
    tar -xzf mydumper.tar.gz && \
    rm mydumper.tar.gz && \
    cd mydumper* && \
    cmake . && \
    make && \
    mv ./mydumper /usr/bin/. && \
    mv ./myloader /usr/bin/. && \
    pip install awscli==$AWSCLI_VERSION && \
    cd / && rm -rf $BUILD_PATH && \
    apk del $BUILD_PACKAGES && \
    rm -f /usr/lib/*.a && \
    (rm -rf "/tmp/"* 2>/dev/null || true) && \
    (rm -rf /var/cache/apk/* 2>/dev/null || true)

COPY ./scripts /scripts
RUN chmod 750 /scripts/init.sh /scripts/run.sh

ENTRYPOINT ["/scripts/init.sh"]
CMD ["/usr/sbin/crond", "-f"]
