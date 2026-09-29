#!/system/bin/sh
# Action button handler for KernelSU manager
# Read-only status display (does not modify configuration)
# v1.7: Shows status of sing-box and module configuration

PATH=/system/bin:/system/xbin
MODDIR=${0%/*}
BASE=/data/adb/gacboost-steering
RUN=$BASE/run
LIVE=$BASE/config.conf
OVR=$BASE/override.conf
DCFG="$MODDIR/config/module.conf.default"

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
  case "$X" in */gb-sb/sing-box|*/gb-t/sb) return 0 ;; esac
  
  local CL=$(tr '\0' ' ' < "/proc/$P/cmdline" 2>/dev/null)
  case "$CL" in *"$RUN/config.json"*) return 0 ;; esac
  return 1
}

T=$(getk TARGETS)
P=$(getk PORTS)
I=$(getk IPS)
PR=$(getk PROTO)
FI=$(getk FINAL)
AU=$(getk AUTO_START)
VER=$(sed -n 's/^version=//p' "$MODDIR/module.prop" 2>/dev/null | head -1)

echo "== GacBoost Steering ${VER:-?} =="
echo "(Web control panel: tap 'Open' in KernelSU manager)"
echo "Target Apps : ${T:-(not configured! edit $LIVE TARGETS)}"
echo "Routing Rules : ports=${P:-unlimited} ips=${I:-unlimited} proto=${PR:-both} final=${FI:-cloudacc} auto_start=${AU:-1}"

if grep -qiE "0100007F:0438[[:space:]]+[0-9A-Fa-f:]+[[:space:]]+0A[[:space:]]" /proc/net/tcp 2>/dev/null \
   || netstat -ltn 2>/dev/null | grep -q ':1080 '; then
  echo "Exit 1080: LISTEN"
else
  echo "Exit 1080: Not listening (tap 'Start Acceleration' in panel)"
fi

IFS= read -r B < "$RUN/.binpath" 2>/dev/null
PIDS=""
for d in /proc/[0-9]*; do
  IFS= read -r n < "$d/comm" 2>/dev/null
  [ "$n" = "sing-box" ] || continue
  p=${d#/proc/}
  is_ours "$p" && PIDS="$PIDS $p"
done

if [ -n "$PIDS" ]; then
  echo "sing-box : Running (this module) pid=$(echo $PIDS | tr ' ' ',') endpoint=${B:-?}"
else
  echo "sing-box : Not running (this module) endpoint=${B:-not selected}"
fi

echo "--- meta.log tail ---"
tail -n 6 "$RUN/meta.log" 2>/dev/null || echo "(empty)"
