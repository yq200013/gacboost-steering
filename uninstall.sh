#!/system/bin/sh
# Uninstall script for GacBoost Steering
# Safely stops module processes and cleans runtime directory
# v1.7: Only kills processes confirmed to belong to this module
# Configuration directory is PRESERVED (can be reused on reinstall)

PATH=/system/bin:/system/xbin
BASE=/data/adb/gacboost-steering
RUN=$BASE/run
OLD=/data/local/tmp/gb-sb

mkdir -p "$RUN" 2>/dev/null
: > "$RUN/disable"
sleep 1

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

# Kill daemon: prefer .pid file, then search cmdline for boot script
IFS= read -r WD < "$RUN/watchdog.pid" 2>/dev/null
[ -n "$WD" ] && kill "$WD" 2>/dev/null

for d in /proc/[0-9]*; do
  c=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null)
  case "$c" in
    *gacboost_steering/boot-completed.sh*)
      k=${d#/proc/}
      [ "$k" != "$$" ] && kill "$k" 2>/dev/null
      ;;
  esac
done
sleep 1

# Stop sing-box: TERM first, then KILL if needed
for d in /proc/[0-9]*; do
  IFS= read -r n < "$d/comm" 2>/dev/null
  [ "$n" = "sing-box" ] || continue
  P=${d#/proc/}
  is_ours "$P" && kill "$P" 2>/dev/null
done
sleep 1

for d in /proc/[0-9]*; do
  IFS= read -r n < "$d/comm" 2>/dev/null
  [ "$n" = "sing-box" ] || continue
  P=${d#/proc/}
  is_ours "$P" && kill -9 "$P" 2>/dev/null
done

# Cleanup runtime directory and v1.6 legacy directory
rm -f "$RUN/sing-box.pid" "$RUN/watchdog.pid" "$RUN/.binpath" 2>/dev/null
rm -rf /dev/gacboost_steering.instance 2>/dev/null
rm -rf "$OLD" 2>/dev/null

echo "Stopped traffic steering (this module only) and cleaned runtime directory"
echo "Configuration preserved at $BASE/config.conf"
echo "To completely remove: rm -rf $BASE"
