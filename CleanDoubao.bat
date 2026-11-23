@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: 请求管理员权限
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 正在请求管理员权限...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

echo =========================================
echo    豆包浏览器右键菜单残留清理工具
echo =========================================
echo.

:: 1. 自动备份相关注册表项
set "BackupPath=%USERPROFILE%\Desktop\Doubao_Reg_Backup_%date:~0,4%%date:~5,2%%date:~8,2%"
if not exist "%BackupPath%" md "%BackupPath%"
echo [1/4] 正在备份相关注册表项到桌面文件夹: %BackupPath% ...
reg export "HKEY_CLASSES_ROOT\Applications" "%BackupPath%\Applications.reg" /y >nul 2>&1
reg export "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts" "%BackupPath%\FileExts.reg" /y >nul 2>&1
reg export "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers" "%BackupPath%\ContextMenuHandlers.reg" /y >nul 2>&1

:: 2. 深度扫描并删除残留项
echo [2/4] 正在深度扫描并清理豆包浏览器残留项...

:: 清理 Applications 下的直接残留
for /f "tokens=*" %%i in ('reg query "HKEY_CLASSES_ROOT\Applications" /s /f "doubao" /k 2^>nul ^| findstr "HKEY"') do (
    echo 发现残留: %%i
    reg delete "%%i" /f >nul 2>&1
)

:: 清理 FileExts 下的 OpenWithList 和 OpenWithProgids
for /f "tokens=*" %%i in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts" /s /f "doubao" 2^>nul ^| findstr "HKEY"') do (
    echo 发现文件关联残留: %%i
    reg delete "%%i" /f >nul 2>&1
)

:: 清理全局右键菜单处理程序
for /f "tokens=*" %%i in ('reg query "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers" /s /f "doubao" 2^>nul ^| findstr "HKEY"') do (
    echo 发现右键菜单残留: %%i
    reg delete "%%i" /f >nul 2>&1
)

:: 清理 Directory 相关的右键菜单
for /f "tokens=*" %%i in ('reg query "HKEY_CLASSES_ROOT\Directory" /s /f "doubao" 2^>nul ^| findstr "HKEY"') do (
    echo 发现目录右键残留: %%i
    reg delete "%%i" /f >nul 2>&1
)

:: 清理 CurrentUser 下的 Classes
for /f "tokens=*" %%i in ('reg query "HKEY_CURRENT_USER\Software\Classes" /s /f "doubao" 2^>nul ^| findstr "HKEY"') do (
    echo 发现用户配置残留: %%i
    reg delete "%%i" /f >nul 2>&1
)

:: 3. 重启资源管理器刷新缓存
echo [3/4] 正在重启 Windows 资源管理器以刷新菜单...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo [4/4] 清理完成！
echo.
echo 如果右键菜单中仍有残留，请尝试重启电脑。
echo 备份文件已保存在桌面，如需恢复可双击运行对应的 .reg 文件。
echo.
pause