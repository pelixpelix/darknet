#!/bin/bash
API=${API:=http://localhost:7070}
I2P=${I2P:=/root/.i2pd}
TUN=$I2P/tunnels.d
keyinfo=keyinfo
keytype="ED25519-SHA512"
chomp() { tr -d "\n"; }
die() { echo "DIE: $1"; exit 1; }
rvalue() { awk -F = '{print $2}' | tr -d " "; }
truncate_file() { truncate -s0 "$@"; }
map() {
  skip=1
  for j in $@; do
    if [ $skip -eq 1 ]; then
      skip=0
      continue
    fi
    for i in $j; do
      $1 "$j"
    done
  done
}
healthcheck() { test $(curl -s $API | grep success | grep -oE '[0-9]+' || echo -n 0) -gt 10; }
do_info() {
file="`grep keys "$1" | rvalue`"
DOMAIN="`$keyinfo "$I2P/$file" | chomp`"
PORT="`grep port "$1" | rvalue`"
echo "$DOMAIN:$PORT"
}
do_dump_client() {
TYPE="`grep ^type "$1" | rvalue`"
if echo "$TYPE" | grep -qi client; then
	HOST="`grep ^destination "$1" | rvalue`"
	PORT="`grep ^port "$1" | rvalue`"
	DPORT="`grep ^destinationport "$1" | rvalue`"
	file="`grep ^keys "$1" | rvalue`"
	KEY="$(base64 -w0 "$I2P/$file")"
	if [ -n "$KEY" ]; then
		KEY=":$KEY"
	fi
	if [ "$PORT" = "$DPORT" ]; then
		echo "$HOST:$DPORT${KEY}"
	else
		echo "$PORT:$HOST:$DPORT${KEY}"
	fi
fi
}

do_dump() {
TYPE="`grep ^type "$1" | rvalue`"
if echo "$TYPE" | grep -qi client; then
file="`grep ^keys "$1" | rvalue`"
HOST="`grep ^host "$1" | rvalue`"
PORT="`grep ^port "$1" | rvalue`"
KEY="$(base64 -w0 "$I2P/$file")"
echo "$TYPE:$HOST:$PORT:$KEY"
fi
}
# 80:nginx:8080:BASE64_KEY
# 80:nginx:8080
# nginx:80
#
do_client_tunnels() {
	for i in $CLIENT; do
		[ -z "$i" ] && continue
		IFS=: read -r PORT HOST DPORT KEY <<< "$i" # 80:nginx:8080:BASE64_KEY
		if [ -z "$KEY" ]; then # max 3 parameters
			if [ -z "$DPORT" ]; then # nginx:80
				DPORT="$HOST"
				HOST="$PORT"
				PORT="$DPORT"
			else # 80:nginx:8080 or nginx:8080:BASE64_KEY
				if echo "$DPORT" | grep -vq ^[0-9]*\$; then # nginx:8080:BASE64_KEY
					KEY="$DPORT"
					DPORT="$HOST"
					HOST="$PORT"
					PORT="$DPORT"
				fi
			fi
		fi
		if [ -n "$KEY" ]; then
			rm -f "$I2P/${HOST}-${PORT}.dat"
			dkeys="keys = ${HOST}-${PORT}.dat"
			echo "$KEY" | base64 -d > "$I2P/${HOST}-${PORT}.dat"
		fi
echo "[${HOST}-${DPORT}]
type = client
address = 0.0.0.0
port = ${PORT}
destination = ${HOST}
destinationport = ${DPORT}
$dkeys
" > "$TUN/${HOST}-${PORT}.conf"
	done
}
do_default() {
	mkdir -p "$I2P" "$TUN"
	[ -n "$HIDDEN_I2P" ] && [ -n "$TUN" ] && rm -rf $TUN/*
#	echo HIDDEN_I2P=$HIDDEN_I2P
	for i in $HIDDEN_I2P; do
		[ -z "$i" ] && continue
		IFS=: read -r TYPE HOST PORT KEY <<< "$i"
NAME="${TYPE}_${HOST}_${PORT}"
echo "[$NAME]
type = $TYPE
host = $HOST
port = $PORT
keys = $NAME.dat" > "$TUN/$NAME.conf"
		test "$TYPE" = server && echo "inport = $PORT" >> "$TUN/$NAME.conf"
		if [ -n "$KEY" ]; then
			echo "$KEY" | base64 -d > "$I2P/$NAME.dat"
		else
			keygen | awk -F : '{print $2}' | base64 -d > "$I2P/$NAME.dat"
		fi
		which keyinfo >/dev/null 2>&1 && keyinfo "$I2P/$NAME.dat" | tr -d "\n" && echo ":$PORT"
	done
	do_client_tunnels
	test -d /usr/share/i2pd/certificates || ln -s /usr/share/i2pd/certificates $I2P/certificates || mkdir -p $I2P/certificates
	exec i2pd --loglevel=${LOGLEVEL:-none} --http.address=0.0.0.0 --httpproxy.address=0.0.0.0 --socksproxy.address=0.0.0.0 --share=${SHARE:-25} --bandwidth=${BANDWIDTH:-X}
}
case "$1" in
	restore)
		do_restore;;
	health|healthcheck)
		healthcheck;;
	status)
		curl -s "$API" | grep success
		curl -s "$API/?page=local_destinations" | grep listitem 
		curl -s "$API/?page=i2p_tunnels"|grep listitem|grep href|sed 's/^.*b32=//'|sed 's/<\/a>.*//'|sed 's/">/\t/'
		;;
	show|info)
		map do_info $TUN/*.conf;;
	dump)
		map do_dump $TUN/*.conf;
		map do_dump_client $TUN/*.conf;;
	sh|bash|/bin/*sh)
		exec "$@";;
	""|default)
		do_default;;
	*)
		exec "$@";;
esac
