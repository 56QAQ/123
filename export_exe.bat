@echo off
rem 导出 Windows 单文件 exe -> build\VoxelArcher.exe
rem 需要已安装 Godot 4.5.1 的导出模板；GODOT 环境变量指向 Godot 4.5 的 console exe。
if "%GODOT%"=="" set GODOT=C:\Users\li125\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe
cd /d "%~dp0"
if not exist build mkdir build
if not exist out mkdir out
"%GODOT%" --headless --path . --import
"%GODOT%" --headless --path . --export-release "Windows Desktop" build\VoxelArcher.exe
if exist build\VoxelArcher.exe (echo 完成：build\VoxelArcher.exe) else (echo 导出失败，请检查导出模板与 export_presets.cfg)
