# syntax=docker/dockerfile:1-labs
FROM alpine:edge AS build

RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing tor curl lyrebird inetutils-telnet
RUN rm -rf /etc/tor/torrc.sample /var/log/tor && chown -R tor:nogroup /var/lib/tor && chmod 700 /var/lib/tor

COPY <<EOF /root/.curlrc
-s
-f
-o /dev/null
-x socks5h://127.0.0.1:9050
--insecure
EOF

COPY <<EOF /etc/tor/torrc.rc
ClientUseIPv6 0
ContactInfo yourname@example.com
DataDirectory /var/lib/tor
DirReqStatistics 0
ExtORPort auto
ExtraInfoStatistics 0
Log notice stderr
PublishServerDescriptor 0
User tor
EOF

COPY <<EOF /etc/tor/torrc.proxy
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:9053
SocksPolicy accept 127.0.0.0/8
SocksPolicy accept 10.0.0.0/8
SocksPolicy accept 192.168.0.0/16
SocksPolicy accept 172.16.0.0/12
SocksPolicy reject *
EOF

COPY <<EOF /etc/tor/torrc.hidden
HiddenServiceDir /var/lib/tor/hidden
EOF

COPY <<EOF /etc/tor/torrc.relay
BridgeRelay 1
ORPort 0.0.0.0:29351
SOCKSPort 0
ExitPolicy reject *:*
ServerTransportPlugin obfs4 exec /usr/bin/lyrebird -enableLogging -logLevel INFO
ServerTransportListenAddr obfs4 0.0.0.0:9999
EOF

COPY <<EOF /etc/tor/torrc.bridge
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/lyrebird
EOF

COPY <<EOF /etc/tor/torrc.entrynodes
EntryNodes {kz},{lk},{lt},{lv},{ee},{ro},{rs},{sa},{si},{th},{tj},{tr},{uz},{vn},{cn},{ly},{ma},{md},{mk},{mn},{mt},{om},{ph},{pl},{qa},{ae},{kw},{am},{az},{bg},{bh},{bn},{by},{cy},{dz},{eg},{ge},{hk},{hr},{hu},{id},{in},{jo},{kg} StrictNodes 1
EOF

COPY <<EOF /etc/tor/torrc.exitnodes
ExitNodes {kz},{lk},{lt},{lv},{ee},{ro},{rs},{sa},{si},{th},{tj},{tr},{uz},{vn},{cn},{ly},{ma},{md},{mk},{mn},{mt},{om},{ph},{pl},{qa},{ae},{kw},{am},{az},{bg},{bh},{bn},{by},{cy},{dz},{eg},{ge},{hk},{hr},{hu},{id},{in},{jo},{kg} StrictNodes 1
EOF

COPY --chmod=777 ./docker-entrypoint.sh /

FROM alpine:edge
COPY --from=build / /

ENV CONTROL_PASSWORD=${CONTROL_PASSWORD:-}
ENV CONTROL_PORT=${CONTROL_PORT:-0.0.0.0:9051}

HEALTHCHECK --interval=30s --timeout=15s \
	CMD test -n "$RELAY" || curl -sfo /dev/null https://check.torproject.org/api/ip || exit 1

EXPOSE 9050 9051 9053
ENTRYPOINT ["/docker-entrypoint.sh"]
