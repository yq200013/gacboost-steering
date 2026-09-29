#!/system/bin/sh
# Installation setup script for KernelSU/Magisk
# Provides fallback implementations for missing installation functions

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$@"; }
command -v set_perm >/dev/null 2>&1 || set_perm() { 
  [ -n "$1" ] && chmod "${4:-0755}" "$1" 2>/dev/null
  return 0
}
command -v set_perm_recursive >/dev/null 2>&1 || set_perm_recursive() { return 0; }

BASE=/data/adb/gacboost-steering
RUN=$BASE/run

mkdir -p "$BASE" "$RUN" 2>/dev/null
chmod 0700 "$BASE" "$RUN" 2>/dev/null

if [ ! -f "$BASE/config.conf" ]; then
  cp -f "$MODPATH/config/module.conf.default" "$BASE/config.conf" 2>/dev/null
  ui_print "- Generated default config: $BASE/config.conf"
else
  ui_print "- Keeping existing config: $BASE/config.conf (not overwritten)"
fi

[ -f "$BASE/config.conf" ] && set_perm "$BASE/config.conf" 0 0 0644

# Set permissions recursively
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/bin/sing-box" 0 0 0755

for f in boot-completed.sh action.sh apply.sh uninstall.sh; do
  [ -f "$MODPATH/$f" ] && set_perm "$MODPATH/$f" 0 0 0755
done

# Cleanup v1.6 legacy directory
rm -rf /data/local/tmp/gb-sb 2>/dev/null

ui_print "- Web control panel: Open module in KernelSU manager (WebUI)"
ui_print "- Or edit directly: $BASE/config.conf (takes effect in 1-2s)"
ui_print "- v1.7: Runtime moved to $RUN (root-only); sing-box copies to secure location"
ui_print "- Disabling/updating daemon requires no reboot (auto-effective within 5s)"
