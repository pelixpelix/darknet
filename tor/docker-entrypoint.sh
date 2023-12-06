#!/bin/sh
export TOR_USER=${TOR_USER:=tor}
export TOR_GROUP=${TOR_GROUP:=nogroup}
export RC=${RC:=/etc/tor/torrc}
export TOR=${TOR:=/var/lib/tor}
TGZ=${TGZ:=/tor.tgz}
die() { echo "DIE: $1"; exit 1; }
restore() { [ -f "$TGZ" ] && tar xzf "$TGZ" -C $TOR --strip-components=3 && rm -rf "$TGZ"; }
show() {
  for x in 1 2 3 4 5 6 7 8 9 10; do
    if [ -n "$RELAY" ]; then
      if [ -f $TOR/fingerprint ] && [ -f $TOR/pt_state/obfs4_bridgeline.txt ]; then
				myip="`curl -qs ident.me`"
				echo "Bridge obfs4 $myip:9999" $(grep -oE '(\w+)$' $TOR/fingerprint | tr -d "\n") $(grep cert $TOR/pt_state/obfs4_bridgeline.txt | tr -d "\n" | grep -oE '( cert=.*)$') # '
        break
      fi
    else
      if [ -n "$HIDDEN" ] && [ -f $TOR/hidden/hostname ] && [ -f $TOR/hidden/hs_ed25519_secret_key ] && [ -f $TOR/hidden/hs_ed25519_public_key ]; then
        echo "HIDDEN_KEY=`cat $TOR/hidden/hostname`:`base64 -w0 $TOR/hidden/hs_ed25519_secret_key`"
        echo "HIDDEN=$HIDDEN"
        break
      fi
    fi
    sleep 1
  done
}
start_default() {
  restore
  mkdir -p $TOR
  chmod -R 'u+rwX,og-rwx' $TOR
  cp $RC.rc $RC
  grep -q DataDirectory $RC || echo "DataDirectory $(realpath $TOR)" >> $RC
  if [ -n "$RELAY" ]; then
    [ -n "$HIDDEN$BRIDGES" ] && die "conflict: RELAY and HIDDEN/BRIDGES both defined"
    cat $RC.relay >> $RC
  else
#    if [ -z "$HIDDEN" ]; then
      cat $RC.proxy >> $RC
#    fi
#  fi
  if [ -n "$HIDDEN" ]; then
    if [ -n "$HIDDEN_KEY" ]; then
      DOMAIN="$(echo $HIDDEN_KEY | awk -F : '{print $1}')"
      echo "DOMAIN: $DOMAIN"
      KEY="$(echo $HIDDEN_KEY | awk -F : '{print $2}')"
      echo "KEY: $KEY"

      mkdir -p "$TOR/hidden"
      echo "$DOMAIN" > "$TOR/hidden/hostname"
      echo "$KEY" | base64 -d > "$TOR/hidden/hs_ed25519_secret_key"
      chmod -R 'u+rwX,og-rwx' $TOR/hidden
      chown -R $TOR_USER:$TOR_GROUP $TOR/hidden
    fi
    echo "HiddenServiceDir $(realpath $TOR)/hidden" >> $RC
    for i in $HIDDEN; do
      echo HiddenServicePort "$i" | sed 's/:/ /' >> $RC
    done
  fi
  if [ -n "$BRIDGES" ]; then
    cat $RC.bridge >> $RC
    echo "$BRIDGES" >> $RC
  else
    cat $RC.entrynodes >> $RC
  fi
  if [ -n "$CONTROL_PASSWORD" ]; then
    echo "ControlPort $CONTROL_PORT" >> $RC
    CONTROL_PASSWORD_HASH=$(/usr/bin/tor --quiet --hash-password "${CONTROL_PASSWORD}")
    echo "HashedControlPassword $CONTROL_PASSWORD_HASH" >> $RC
  fi
  cat $RC.exitnodes >> $RC
  [ -n "$CONF" ] && echo "$CONF" >> $RC
fi
  if tor --quiet --verify-config -f $RC; then
    [ -d $TOR/hidden ] && chown -R $TOR_USER:$TOR_GROUP $TOR/hidden
    [ -n "$RELAY$HIDDEN" ] && "$0" show &
    exec tor
  else
    tor --verify-config -f $RC
    cat $RC
    sleep 60
    exit 1
  fi
}
case "$1" in
  restore)
    restore;;
  show|info)
    show;;
  sh|bash)
    exec "$1";;
  "")
    start_default;;
  *)
    exec "$@";;
esac
