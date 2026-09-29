#!/system/bin/sh
# KernelSU 管理器的「Action」按钮：只读地打印现状（不改配置）
#   v1.7：运行态路径改到 /data/adb/gacboost-steering/run；sing-box 只显示"本模块自己的"；
#         出口检查用 /proc/net/tcp；TARGETS 用三级优先级。
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

T=$(getk TARGETS); P=$(getk PORTS); I=$(getk IPS); PR=$(getk PROTO); FI=$(getk FINAL); AU=$(getk AUTO_START)
VER=$(sed -n 's/^version=//p' "$MODDIR/module.prop" 2>/dev/null | head -1)

echo "== GacBoost Steering ${VER:-?} =="
echo "（图形控制面板：在 KernelSU 管理器里点本模块的「打开」）"
echo "目标 App : ${T:-（未配置！编辑 $LIVE 的 TARGETS）}"
echo "分流规则 : ports=${P:-不限} ips=${I:-不限} proto=${PR:-both} final=${FI:-cloudacc} auto_start=${AU:-1}"
if grep -qiE "0100007F:0438[[:space:]]+[0-9A-Fa-f:]+[[:space:]]+0A[[:space:]]" /proc/net/tcp 2>/dev/null \
   || netstat -ltn 2>/dev/null | grep -q ':1080 '; then
  echo "出口 1080: LISTEN"
else
  echo "出口 1080: 未监听（去 GacBoost 面板点\"开加速\"）"
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
  echo "sing-box : 运行中（本模块）pid=$(echo $PIDS | tr ' ' ',')  落点=${B:-?}"
else
  echo "sing-box : 未运行（本模块）  落点=${B:-未选定}"
fi
echo "--- meta.log 末尾 ---"
tail -n 6 "$RUN/meta.log" 2>/dev/null || echo "(无)"
