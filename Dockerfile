FROM golang:1-alpine AS build

ARG VERSION="0.6.0"
ARG CHECKSUM="dfe5402d53501a44a15246862e38062536691a46fd804d45b1f9573627370d16"

ADD https://github.com/prometheus/collectd_exporter/archive/v$VERSION.tar.gz /tmp/collectd_exporter.tar.gz

RUN [ "$(sha256sum /tmp/collectd_exporter.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add curl make && \
    tar -C /tmp -xf /tmp/collectd_exporter.tar.gz && \
    mkdir -p /go/src/github.com/prometheus && \
    mv /tmp/collectd_exporter-$VERSION /go/src/github.com/prometheus/collectd_exporter && \
    cd /go/src/github.com/prometheus/collectd_exporter && \
      make build

RUN mkdir -p /rootfs/bin && \
      cp /go/src/github.com/prometheus/collectd_exporter/collectd_exporter /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 9103/tcp 25826:25826/udp
ENTRYPOINT ["/bin/collectd_exporter"]
