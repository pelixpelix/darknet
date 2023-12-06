# syntax=docker/dockerfile:1-labs

FROM alpine AS builder
RUN apk add --no-cache ca-certificates build-base make gcc autoconf libsodium-dev git curl \
			boost boost-dev boost-chrono boost-filesystem boost-system boost-thread \
			boost-date_time boost-program_options libssl3 openssl3-dev nss zlib-dev openssh \
			inetutils-telnet

FROM alpine AS build
RUN apk add --no-cache curl i2pd bash libssl3 openssl3-dev nss zlib-dev

COPY --chmod=777 ./docker-entrypoint.sh /

FROM scratch
COPY --from=build / /

EXPOSE 7070 4444 4447
HEALTHCHECK CMD test $(curl -s http://localhost:7070 | grep success | grep -oE '[0-9]+' || echo -n 0) -gt 10
ENTRYPOINT ["/docker-entrypoint.sh"]
