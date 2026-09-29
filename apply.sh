#!/system/bin/sh
# 供命令行 / 旧版 WebUI 调用的"立即重载"入口；v1.7 的 WebUI 直接写 run/reload，不再依赖本脚本。
#   v1.7 改动：TARGETS 回显用与守护脚本相同的三级优先级（override.conf → config.conf → 模块默认）
#   + 运行态目录改为 /data/adb/gacboost-steering/run（root-only）。
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

T=$(getk TARGETS)
if [ -z "$T" ]; then
  echo "TARGETS 为空 -> 将停止引流"
else
  echo "目标: $T"
fi
mkdir -p "$RUN" 2>/dev/null
: > "$RUN/reload" 2>/dev/null
echo "已请求立即重载（1~2s 内生效）"
