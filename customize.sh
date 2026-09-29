#!/system/bin/sh
# 安装阶段（KernelSU/Magisk 会 source 本脚本并提供 ui_print / set_perm / MODPATH）
# 兜底定义：若安装器未提供（例如手工执行），也不会因缺函数而中断。
#   v1.7 修正：fallback set_perm 的参数位置（真实签名是 set_perm <file> <owner> <group> <mode>，
#   原实现用 $3(=group) 当路径去 chmod，是错的）。
command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$@"; }
command -v set_perm >/dev/null 2>&1 || set_perm() { [ -n "$1" ] && chmod "${4:-0755}" "$1" 2>/dev/null; return 0; }
command -v set_perm_recursive >/dev/null 2>&1 || set_perm_recursive() { return 0; }

BASE=/data/adb/gacboost-steering
RUN=$BASE/run
mkdir -p "$BASE" "$RUN" 2>/dev/null
chmod 0700 "$BASE" "$RUN" 2>/dev/null

if [ ! -f "$BASE/config.conf" ]; then
  cp -f "$MODPATH/config/module.conf.default" "$BASE/config.conf" 2>/dev/null
  ui_print "- 已生成默认配置：$BASE/config.conf"
else
  ui_print "- 保留已有配置：$BASE/config.conf（未被覆盖）"
fi
[ -f "$BASE/config.conf" ] && set_perm "$BASE/config.conf" 0 0 0644

# 权限（注意：webroot 不手工设权限 —— KernelSU 安装时会自行设置 WebUI 的权限与 SELinux context）
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/bin/sing-box" 0 0 0755
for f in boot-completed.sh action.sh apply.sh uninstall.sh; do
  [ -f "$MODPATH/$f" ] && set_perm "$MODPATH/$f" 0 0 0755
done

# v1.7：清理 v1.6 及更早版本遗留在公共临时目录的运行态（那里曾被 root 执行过，属安全边界问题）
rm -rf /data/local/tmp/gb-sb 2>/dev/null

ui_print "- 图形控制面板：在 KernelSU 管理器里点本模块的「打开」（WebUI）"
ui_print "- 也可直接编辑：$BASE/config.conf（保存后 1~2s 生效）"
ui_print "- v1.7：运行态改到 $RUN（root-only）；sing-box 会由守护脚本复制到安全落点后执行"
ui_print "- 禁用/更新守护脚本无需重启手机（≤5s 自动生效）"
