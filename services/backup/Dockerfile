FROM alpine:edge

ENV PACKAGES="mysql-client" \
    LIB_PACKAGES="glib-dev mariadb-dev zlib-dev pcre-dev libressl-dev python2 bash curl rsync" \
    BUILD_PACKAGES="cmake build-base git py2-pip" \
    BUILD_PATH="/opt/mydumper-src/"

RUN apk --no-cache add \
          $PACKAGES \
          $BUILD_PACKAGES \
          $LIB_PACKAGES && \
    git clone https://github.com/maxbube/mydumper.git $BUILD_PATH && \
    cd $BUILD_PATH && \
    cmake . && \
    make && \
    mv ./mydumper /usr/bin/. && \
    mv ./myloader /usr/bin/. && \
    pip install awscli && \
    cd / && rm -rf $BUILD_PATH && \
    apk del $BUILD_PACKAGES && \
    rm -f /usr/lib/*.a && \
    (rm "/tmp/"* 2>/dev/null || true) && \
    (rm -rf /var/cache/apk/* 2>/dev/null || true)

COPY ./scripts /scripts
RUN chmod 750 /scripts/init.sh /scripts/run.sh

ENTRYPOINT ["/scripts/init.sh"]
CMD ["/usr/sbin/crond", "-f"]
