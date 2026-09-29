#!/system/bin/sh
# GacBoost Steering Daemon - v1.7.4
# Manages sing-box lifecycle and configuration monitoring
# Runtime path: /data/adb/gacboost-steering/run

PATH=/system/bin:/system/xbin
MODDIR=${0%/*}
BASE=/data/adb/gacboost-steering
RUN=$BASE/run
LIVE=$BASE/config.conf
OVR=$BASE/override.conf
DCFG="$MODDIR/config/module.conf.default"
WD_PID="$RUN/watchdog.pid"
SB_PID="$RUN/sing-box.pid"
RELOAD_FLAG="$RUN/reload"
DISABLE_FLAG="$RUN/disable"

# Three-level priority: override.conf > config.conf > module.conf.default
getk() {
  local key="$1"
  local v
  
  v=$(sed -n "s/^${key}=//p" "$OVR" 2>/dev/null | head -1 | tr -d '\r')
  [ -z "$v" ] && v=$(sed -n "s/^${key}=//p" "$LIVE" 2>/dev/null | head -1 | tr -d '\r')
  [ -z "$v" ] && v=$(sed -n "s/^${key}=//p" "$DCFG" 2>/dev/null | head -1 | tr -d '\r')
  echo "$v"
}

is_ours() {
  local P="$1"
  [ -n "$P" ] || return 1
  [ -d "/proc/$P" ] || return 1
  
  local X=$(readlink "/proc/$P/exe" 2>/dev/null)
  case "$X" in
    */gb-sb/sing-box|*/gb-t/sb) return 0 ;;
  esac
  
  local CL=$(tr '\0' ' ' < "/proc/$P/cmdline" 2>/dev/null)
  case "$CL" in
    *"$RUN/config.json"*) return 0 ;;
  esac
  return 1
}

mkdir -p "$RUN" 2>/dev/null
chmod 0700 "$RUN" 2>/dev/null
chmod 0700 "$BASE" 2>/dev/null

echo "$$" > "$WD_PID"

# Main daemon loop
while true; do
  [ -f "$DISABLE_FLAG" ] && {
    rm -f "$WD_PID" 2>/dev/null
    exit 0
  }
  
  if [ -f "$RELOAD_FLAG" ]; then
    rm -f "$RELOAD_FLAG" 2>/dev/null
    # Trigger configuration reload logic here
  fi
  
  sleep 5
done
