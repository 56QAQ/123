#!/bin/bash
# 导出 Windows 单文件 exe 并做冒烟测试。用法: ./run_export.sh
# 产物: build/VoxelArcher.exe   (可用环境变量 GODOT 指定引擎路径)
G="${GODOT:-/c/Users/li125/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")"
QUIET_FUNCS_ONLY=1 source tools/quiet_window.sh
source tools/build_lock.sh     # 并行时构建 / 截图 / 导出排队
mkdir -p out build
rm -f build/VoxelArcher.exe out/exe_test.png
timeout 300 "$G" --headless --path . --import > out/import.log 2>&1
timeout 600 "$G" --headless --path . --export-release "Windows Desktop" build/VoxelArcher.exe > out/export.log 2>&1
if [ ! -f build/VoxelArcher.exe ]; then echo "EXPORT FAILED (见 out/export.log)"; tail -5 out/export.log; exit 1; fi
# 冒烟：exe 自己开一局、打到 4 秒的战斗并自渲染一张截图(证明 3D 战斗、数据、字体都被打进 pck)
#   (冒烟窗口 1×1、不抢焦点：exe 旁边临时放 override.cfg，跑完删掉；SHOW_WINDOW=1 看窗口)
quiet_window_exe build
timeout 90 ./build/VoxelArcher.exe --quit-after 1500 -- --state=battle --battle_time=4 --frames=60 --probe_wrap --shot="$(pwd -W)/out/exe_test.png" > out/exe_run.log 2>&1
quiet_window_exe_done build
# 中文断行(导出包要带文本服务器断行数据，project.godot: internationalization/locale/include_text_server_data)
grep -o "WRAP_PROBE.*" out/exe_run.log | head -1
if [ -f out/exe_test.png ] && [ "$(stat -c %s out/exe_test.png)" -gt 60000 ]; then
  echo "OK  $(pwd -W)\build\VoxelArcher.exe  ($(du -h build/VoxelArcher.exe | cut -f1))  冒烟测试通过(已自渲染截图 out/exe_test.png)"
else
  echo "SMOKE TEST FAILED (见 out/exe_run.log)"; exit 2
fi
