# syntax=docker/dockerfile:1-labs
FROM alpine AS builder
RUN apk --no-cache --update --upgrade add privoxy ca-certificates curl
#RUN which privoxy
#RUN rm -f /etc/privoxy/config.new
RUN for i in /etc/privoxy/*.new; do mv $i `basename $i .new`; done
ADD config /etc/privoxy/
EXPOSE 8118
CMD ["/usr/sbin/privoxy", "--no-daemon", "/etc/privoxy/config"]
