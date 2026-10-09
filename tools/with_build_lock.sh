#!/bin/bash
# 拿着构建锁跑一条命令(自己写的预览 / 截图脚本要读 assets/、scenes/ 时用，免得撞上别人正在重建)：
#   tools/with_build_lock.sh "$GODOT" --path . --script res://out/xxx.gd --quit-after 600
cd "$(dirname "$0")/.."
source tools/quiet_window.sh
source tools/build_lock.sh
"$@"
