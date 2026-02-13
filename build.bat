@echo off
REM 冰阅 · 应用构建脚本 (Windows)
REM 此脚本用于构建Android APK文件

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   冰阅 · APP构建开始
echo ========================================
echo.

REM 检查环境
echo 检查环境要求...

where cordova >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 未找到Cordova，请先全局安装: npm install -g cordova
    pause
    exit /b 1
)

where gradle >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 未找到Gradle
    echo.
    echo 请访问: https://gradle.org/install/
    pause
    exit /b 1
)

if not defined ANDROID_HOME (
    echo [错误] 未设置ANDROID_HOME环境变量
    echo.
    echo 请先安装Android SDK并设置ANDROID_HOME
    pause
    exit /b 1
)

for /f "tokens=*" %%a in ('cordova --version') do set CORDOVA_VER=%%a
for /f "tokens=*" %%a in ('node --version') do set NODE_VER=%%a
for /f "tokens=*" %%a in ('npm --version') do set NPM_VER=%%a

echo [完成] Cordova版本: %CORDOVA_VER%
echo [完成] Node版本: %NODE_VER%
echo [完成] npm版本: %NPM_VER%
echo.

REM 切到项目目录
cd /d "%~dp0"

REM 安装项目依赖
echo [正在进行] 安装项目依赖...
call npm install

REM 检查是否已添加Android平台
if not exist "platforms\android" (
    echo [进行中] 添加Android平台...
    call cordova platform add android@latest
) else (
    echo [完成] Android平台已存在
)

echo.

REM 构建Release版本
echo [正在进行] 构建APK文件...
call cordova build android --release

echo.
echo ========================================
echo   构建完成!
echo ========================================
echo.

if exist "platforms\android\app\build\outputs\apk\release\app-release.apk" (
    for %%F in ("platforms\android\app\build\outputs\apk\release\app-release.apk") do (
        echo [完成] 签名APK文件: %%F
        echo 文件大小: %%~zF 字节
    )
) else if exist "platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk" (
    echo [警告] 生成了未签名APK
    echo 路径: platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk
    echo.
    echo 需要签名后才能发布。使用以下命令:
    echo   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 ^
    echo     -keystore my-release-key.jks ^
    echo     app-release-unsigned.apk alias_name
)

pause
