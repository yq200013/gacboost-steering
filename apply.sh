#!/system/bin/sh
# Reload configuration on-demand entry point
# Triggered by WebUI or command line

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

T=$(getk TARGETS)
if [ -z "$T" ]; then
  echo "TARGETS is empty -> will stop traffic steering"
else
  echo "Targets: $T"
fi

mkdir -p "$RUN" 2>/dev/null
: > "$RUN/reload" 2>/dev/null

echo "Reload requested (effective within 1-2s)"
