@echo off
rem 重建整个项目：动画 + 模型网格 + 场景 + 棋子模型套件(武器) + 世界模型(卡车/断壁残垣/祭坛)。
rem 用法：先把 GODOT 环境变量设成 Godot 4.5 的 exe 路径(建议 console 版)，或直接编辑下面这行。
if "%GODOT%"=="" set GODOT=C:\Users\li125\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe
cd /d "%~dp0"
if not exist out mkdir out
echo [1/4] 烘焙动画 ...
"%GODOT%" --path . --script res://tools/build_anims.gd --quit-after 20
echo [2/4] 雕刻体素 + 网格 + 场景 ...
"%GODOT%" --path . --script res://tools/build_all.gd --quit-after 20
echo [3/4] 棋子模型套件(武器网格) ...
"%GODOT%" --path . --script res://tools/build_kits.gd --quit-after 20
echo [4/4] 世界模型 ...
"%GODOT%" --path . --script res://tools/build_world.gd --quit-after 20
echo 完成。运行主场景：  "%GODOT%" --path .
