# syntax=docker/dockerfile:1-labs
FROM alpine AS builder
RUN apk --no-cache --update --upgrade add privoxy ca-certificates curl
WORKDIR /etc/privoxy
RUN for i in *.new; do mv $i `basename $i .new`; done
COPY config /etc/privoxy/config
EXPOSE 8118
CMD ["/usr/sbin/privoxy", "--no-daemon", "/etc/privoxy/config"]
