#!/system/bin/sh
# 卸载：① 落 disable（让守护脚本自己退） ② 杀**本模块自己的**守护脚本 ③ 停**本模块自己的** sing-box
#       ④ 清运行目录与单实例锁。配置目录【保留】（重装可继续用）
#
# v1.7 改动：
#  · 只杀"确认属于本模块"的进程：sing-box 需 /proc/PID/exe 指向我们的副本，
#    或 cmdline 含 -c /data/adb/gacboost-steering/run/config.json；
#    **不再**按进程名 comm==sing-box 全局 kill（那会误杀其它模块/用户的 sing-box）。
#  · 运行目录改到 /data/adb/gacboost-steering/run（root-only），并清理 v1.6 的旧目录。
PATH=/system/bin:/system/xbin
BASE=/data/adb/gacboost-steering
RUN=$BASE/run
OLD=/data/local/tmp/gb-sb

mkdir -p "$RUN" 2>/dev/null
: > "$RUN/disable"
sleep 1

is_ours() {
  P="$1"
  [ -n "$P" ] || return 1
  [ -d "/proc/$P" ] || return 1
  X=$(readlink "/proc/$P/exe" 2>/dev/null)
  case "$X" in
    */gb-sb/sing-box|*/gb-t/sb) return 0 ;;
  esac
  CL=$(tr '\0' ' ' < "/proc/$P/cmdline" 2>/dev/null)
  case "$CL" in
    *"$RUN/config.json"*) return 0 ;;
  esac
  return 1
}

# ② 杀守护脚本：优先 pid 文件；再用 /proc/*/cmdline 精确匹配本模块脚本路径
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

# ③ 停本模块的 sing-box（先 TERM 再 KILL；只碰 is_ours 的）
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

# ④ 清理（含 v1.6 遗留的公共临时目录 —— 那里曾被执行过，属安全边界问题）
rm -f "$RUN/sing-box.pid" "$RUN/watchdog.pid" "$RUN/.binpath" 2>/dev/null
rm -rf /dev/gacboost_steering.instance 2>/dev/null
rm -rf "$OLD" 2>/dev/null

echo "已停止引流（仅本模块进程）并清理运行目录；配置保留在 $BASE/config.conf"
echo "如需彻底清除： rm -rf $BASE"
