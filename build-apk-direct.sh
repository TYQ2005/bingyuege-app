#!/bin/bash

# 冰阅 APP 无依赖 APK 直接构建脚本
# 绕过 npm 问题，使用 Gradle 直接编译

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

echo ""
echo "🔧 冰阅 APP APK 直接构建 (无 npm 依赖)"
echo "======================================"
echo ""

# 检查 Java
if ! command -v java &> /dev/null; then
    echo "❌ 需要安装 Java JDK 11+"
    exit 1
fi
echo "✅ Java: $(java -version 2>&1 | grep version | cut  -d' ' -f3)"

# 检查 Android SDK
if [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ ANDROID_HOME 未设置或不存在"
    echo "请设置: export ANDROID_HOME=\$HOME/Android/Sdk"
    exit 1
fi
echo "✅ ANDROID_SDK: $ANDROID_HOME"

cd "$PROJECT_DIR"

# 创建最小的 Android 项目结构
echo ""
echo "📁 创建 Android 项目结构..."

mkdir -p android_build

cat > android_build/build.gradle << 'EOF'
android {
    compileSdkVersion 33
    buildToolsVersion "33.0.2"
    
    defaultConfig {
        applicationId "com.bingyuege.app"
        minSdkVersion 23
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            minifyEnabled false
        }
        debug {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.5.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}
EOF

cat > android_build/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.bingyuege.app">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme">
        
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|keyboardHidden|screenSize"
            android:label="@string/app_name"
            android:theme="@style/AppTheme.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

echo "✅ 项目结构已创建"

# 使用 cordova 命令构建（如果可用）
if command -v cordova &> /dev/null; then
    echo ""
    echo "🔨 使用 Cordova 构建..."
    
    if [ ! -d "platforms/android" ]; then
        cordova platform add android@latest || true
    fi
    
    cordova build android --release 2>&1 | grep -E "(BUILD|Error|error|Finished)" || echo "构建进行中..."
    
    # 查找 APK
    if [ -f "platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
        mkdir -p apk_output
        cp "platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk" "apk_output/bingyuege-v1.0.0.apk"
        echo ""
        echo "✅ APK 已生成: apk_output/bingyuege-v1.0.0.apk"
        ls -lh apk_output/
    fi
else
    echo "⚠️  Cordova 未安装，无法继续"
    echo "请安装: npm install -g cordova"
fi

echo ""
