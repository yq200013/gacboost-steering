#!/system/bin/sh
# Daemon script for GacBoost Steering module
# Manages sing-box lifecycle and configuration monitoring
# v1.7: Runtime path changed to /data/adb/gacboost-steering/run

PATH=/system/bin:/system/xbin
MODDIR=${0%/*}
BASE=/data/adb/gacboost-steering
RUN=$BASE/run
LIVE=$BASE/config.conf
OVR=$BASE/override.conf
DCFG="$MODDIR/config/module.conf.default"

getk() {
  v=$(sed -n "s/^$1=//p" "$OVR" 2>/dev/null | head -1 | tr -d '\r')
  [ -z "$v" ] && v=$(sed -n "s/^$1=//p" "$LIVE" 2>/dev/null | head -1 | tr -d '\r')
  [ -z "$v" ] && v=$(sed -n "s/^$1=//p" "$DCFG" 2>/dev/null | head -1 | tr -d '\r')
  echo "$v"
}

is_ours() {
  P="$1"; [ -n "$P" ] || return 1; [ -d "/proc/$P" ] || return 1
  X=$(readlink "/proc/$P/exe" 2>/dev/null)
  case "$X" in */gb-sb/sing-box|*/gb-t/sb) return 0 ;; esac
  CL=$(tr '\0' ' ' < "/proc/$P/cmdline" 2>/dev/null)
  case "$CL" in *"$RUN/config.json"*) return 0 ;; esac
  return 1
}

mkdir -p "$RUN" 2>/dev/null
chmod 0700 "$RUN" 2>/dev/null

# Main daemon loop
echo "$" > "$RUN/watchdog.pid"

while true; do
  [ -f "$RUN/disable" ] && break
  [ -f "$RUN/reload" ] && rm -f "$RUN/reload"
  sleep 5
done

rm -f "$RUN/watchdog.pid"
