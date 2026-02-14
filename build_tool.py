#!/usr/bin/env python3

"""
冰阅 Android APK 构建和发布工具 (v2.1)
======================================

纯Python实现的构建工具，无需复杂的环境配置
支持 Debug/Release 构建、签名、优化等功能
"""

import os
import sys
import json
import subprocess
import shutil
import argparse
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict

class BingyuegeBuilder:
    """冰阅应用构建工具"""
    
    def __init__(self, project_dir: str = "."):
        self.project_dir = Path(project_dir).resolve()
        self.build_dir = self.project_dir / "build"
        self.release_dir = self.project_dir / "release"
        self.platforms_dir = self.project_dir / "platforms"
        self.android_dir = self.platforms_dir / "android"
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.version = self._load_version()
        self.config = self._load_config()
        
        # 创建必要的目录
        self.build_dir.mkdir(exist_ok=True)
        self.release_dir.mkdir(exist_ok=True)
    
    def _load_version(self) -> str:
        """从 package.json 读取版本号"""
        try:
            with open(self.project_dir / "package.json", "r", encoding='utf-8') as f:
                config = json.load(f)
                return config.get("version", "1.0.0")
        except:
            return "1.0.0"
    
    def _load_config(self) -> Dict:
        """加载构建配置"""
        config_file = self.project_dir / "config.xml"
        config = {
            "app_id": "com.bingyuege.app",
            "app_name": "冰阅",
            "min_sdk": 23,
            "target_sdk": 34
        }
        
        # 尝试从 config.xml 读取
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if 'id="com.' in content:
                        start = content.find('id="') + 4
                        end = content.find('"', start)
                        config["app_id"] = content[start:end]
                    if '<name>' in content:
                        start = content.find('<name>') + 6
                        end = content.find('</name>', start)
                        config["app_name"] = content[start:end]
            except:
                pass
        
        return config
    
    def _run_command(self, cmd: List[str], cwd: Optional[Path] = None, 
                     capture: bool = False, show_output: bool = True) -> Optional[str]:
        """运行命令"""
        try:
            if show_output:
                print(f"▶ {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                cwd=cwd or self.project_dir,
                capture_output=capture,
                text=True,
                timeout=600
            )
            
            if result.returncode != 0:
                if result.stderr:
                    print(f"❌ 错误: {result.stderr[:200]}")
                return None
            
            if capture and result.stdout:
                return result.stdout.strip()
            return "success"
        except subprocess.TimeoutExpired:
            print(f"❌ 命令超时")
            return None
        except Exception as e:
            print(f"❌ 错误: {str(e)}")
            return None
    
    def check_environment(self) -> bool:
        """检查开发环境"""
        print("\n🔍 检查开发环境...")
        
        tools = {
            "node": ["node", "--version"],
            "npm": ["npm", "--version"],
            "java": ["java", "-version"],
            "javac": ["javac", "-version"]
        }
        
        available = {}
        for tool_name, cmd in tools.items():
            result = self._run_command(cmd, capture=True, show_output=False)
            if result:
                version_line = result.split('\n')[0] if result else "unknown"
                print(f"  ✓ {tool_name}: {version_line[:60]}")
                available[tool_name] = True
            else:
                print(f"  ⚠ {tool_name}: 未安装")
                available[tool_name] = False
        
        # 检查 Cordova
        if shutil.which("cordova"):
            result = self._run_command(["cordova", "--version"], capture=True, show_output=False)
            if result:
                print(f"  ✓ cordova: {result}")
                available["cordova"] = True
        else:
            print(f"  ⚠ cordova: 未安装")
            available["cordova"] = False
        
        return available.get("node") and available.get("npm")
    
    def install_dependencies(self) -> bool:
        """安装项目依赖"""
        print("\n📥 安装项目依赖...")
        
        # 检查 node_modules
        if not (self.project_dir / "node_modules").exists():
            print("  📦 安装 npm 包...")
            result = self._run_command(["npm", "install", "--legacy-peer-deps"])
            if not result:
                print("  ⚠ npm install 可能有问题，继续...")
        else:
            print("  ✓ npm 包已安装")
        
        # 检查 Cordova
        if not shutil.which("cordova"):
            print("  📦 安装 Cordova CLI...")
            result = self._run_command(["npm", "install", "-g", "cordova@latest", "--legacy-peer-deps"], 
                                     show_output=False)
            if not result:
                print("  ℹ Cordova 安装失败，将使用 npx cordova")
        else:
            print("  ✓ Cordova 已安装")
        
        return True
    
    def get_cordova_cmd(self) -> str:
        """获取 Cordova 命令"""
        if shutil.which("cordova"):
            return "cordova"
        else:
            return "npx cordova"
    
    def init_cordova(self) -> bool:
        """初始化 Cordova 项目"""
        print("\n⚙️ 初始化 Cordova 项目...")
        
        cordova_cmd = self.get_cordova_cmd()
        
        # 添加 Android 平台
        if not self.android_dir.exists():
            print("  📱 添加 Android 平台...")
            result = self._run_command([cordova_cmd, "platform", "add", "android@latest"])
            if not result:
                return False
            print("  ✓ Android 平台已添加")
        else:
            print("  ✓ Android 平台已存在")
            # 更新平台
            print("  🔄 更新 Android 平台...")
            self._run_command([cordova_cmd, "platform", "update", "android@latest"], show_output=False)
        
        return True
    
    def build_debug(self) -> bool:
        """构建 Debug APK"""
        print("\n🔨 构建 Debug APK...")
        
        cordova_cmd = self.get_cordova_cmd()
        result = self._run_command([cordova_cmd, "build", "android", "--debug"])
        if not result:
            print("  ❌ Debug APK 构建失败")
            return False
        
        # 查找 APK 文件
        debug_apk = self.android_dir / "app" / "build" / "outputs" / "apk" / "debug" / "app-debug.apk"
        if debug_apk.exists():
            output_name = f"bingyuege-app-debug-{self.version}-{self.timestamp}.apk"
            output_path = self.release_dir / output_name
            shutil.copy2(debug_apk, output_path)
            
            # 计算 MD5
            md5 = self._calculate_md5(output_path)
            size_mb = output_path.stat().st_size / 1024 / 1024
            
            print(f"  ✓ Debug APK: {output_name}")
            print(f"    - 大小: {size_mb:.2f} MB")
            print(f"    - MD5: {md5}")
            return True
        else:
            print(f"  ❌ APK 未找到: {debug_apk}")
            return False
    
    def build_release(self) -> bool:
        """构建 Release APK"""
        print("\n🔨 构建 Release APK...")
        
        cordova_cmd = self.get_cordova_cmd()
        result = self._run_command([cordova_cmd, "build", "android", "--release"])
        if not result:
            print("  ❌ Release APK 构建失败")
            return False
        
        # 查找 APK 文件
        release_apk = (self.android_dir / "app" / "build" / "outputs" / 
                      "apk" / "release" / "app-release-unsigned.apk")
        if release_apk.exists():
            output_name = f"bingyuege-app-release-{self.version}-{self.timestamp}-unsigned.apk"
            output_path = self.release_dir / output_name
            shutil.copy2(release_apk, output_path)
            
            # 计算 MD5
            md5 = self._calculate_md5(output_path)
            size_mb = output_path.stat().st_size / 1024 / 1024
            
            print(f"  ✓ Release APK: {output_name}")
            print(f"    - 大小: {size_mb:.2f} MB")
            print(f"    - MD5: {md5}")
            return True
        else:
            print(f"  ❌ APK 未找到: {release_apk}")
            return False
    
    def _calculate_md5(self, file_path: Path) -> str:
        """计算文件 MD5"""
        md5_hash = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                md5_hash.update(chunk)
        return md5_hash.hexdigest()
    
    def sign_apk(self, apk_file: str, keystore: str = ".keystore", alias: str = "bingyuege") -> bool:
        """签名 APK"""
        print(f"\n🔐 签名 APK: {apk_file}...")
        
        keystore_path = self.project_dir / keystore
        if not keystore_path.exists():
            print(f"  ⚠ 未找到签名文件: {keystore}")
            print(f"  请先创建密钥库:")
            print(f"  keytool -genkey -v -keystore {keystore_path} -keyalg RSA -keysize 2048 -validity 10000 -alias {alias}")
            return False
        
        if not shutil.which("jarsigner"):
            print(f"  ❌ jarsigner 未安装，无法签名")
            return False
        
        apk_path = self.release_dir / apk_file
        if not apk_path.exists():
            print(f"  ❌ APK 文件未找到: {apk_file}")
            return False
        
        # 签名
        result = self._run_command([
            "jarsigner", "-verbose",
            "-sigalg", "SHA256withRSA",
            "-digestalg", "SHA-256",
            "-keystore", str(keystore_path),
            str(apk_path),
            alias
        ], show_output=False)
        
        if result:
            print(f"  ✓ APK 签名成功")
            return True
        else:
            print(f"  ⚠ 签名可能失败，请检查")
            return False
    
    def optimize_apk(self, apk_file: str) -> bool:
        """优化 APK (zipalign)"""
        print(f"\n⚡ 优化 APK: {apk_file}...")
        
        if not shutil.which("zipalign"):
            print(f"  ⚠ zipalign 未安装，跳过优化")
            return False
        
        apk_path = self.release_dir / apk_file
        optimized_path = self.release_dir / apk_file.replace(".apk", "-optimized.apk")
        
        result = self._run_command([
            "zipalign", "-v", "4",
            str(apk_path),
            str(optimized_path)
        ], show_output=False)
        
        if result and optimized_path.exists():
            print(f"  ✓ APK 优化成功: {optimized_path.name}")
            return True
        else:
            print(f"  ⚠ 优化失败")
            return False
    
    def clean_build(self) -> bool:
        """清理构建文件"""
        print("\n🧹 清理构建文件...")
        
        items_to_remove = [
            (self.android_dir, "platforms/android"),
            (self.project_dir / "plugins", "plugins"),
            (self.project_dir / "node_modules", "node_modules")
        ]
        
        for path, name in items_to_remove:
            if path.exists():
                shutil.rmtree(path)
                print(f"  ✓ 删除 {name}")
        
        return True
    
    def generate_report(self) -> None:
        """生成构建报告"""
        print("\n📄 生成构建报告...")
        
        report_file = self.build_dir / f"BUILD_REPORT_{self.timestamp}.md"
        
        apk_files = list(self.release_dir.glob("*.apk"))
        
        with open(report_file, "w", encoding='utf-8') as f:
            f.write("# 冰阅 Android APK 构建报告\n\n")
            f.write(f"**构建时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**应用版本**: {self.version}\n")
            f.write(f"**应用名称**: {self.config['app_name']}\n")
            f.write(f"**应用 ID**: {self.config['app_id']}\n")
            f.write(f"**项目目录**: {self.project_dir}\n\n")
            
            f.write("## 生成的 APK 文件\n\n")
            if apk_files:
                for apk in sorted(apk_files, reverse=True)[:5]:
                    size = apk.stat().st_size / 1024 / 1024
                    md5 = self._calculate_md5(apk)
                    f.write(f"- **{apk.name}**\n")
                    f.write(f"  - 大小: {size:.2f} MB\n")
                    f.write(f"  - MD5: {md5}\n")
            else:
                f.write("- 未生成 APK 文件\n")
            
            f.write("\n## 系统信息\n\n")
            f.write(f"- **Python**: {sys.version.split()[0]}\n")
            f.write(f"- **操作系统**: {os.uname().sysname}\n")
            f.write(f"- **项目路径**: {self.project_dir}\n")
            
            f.write("\n## 配置信息\n\n")
            f.write(f"- **最小 SDK**: API {self.config['min_sdk']}\n")
            f.write(f"- **目标 SDK**: API {self.config['target_sdk']}\n")
        
        print(f"  ✓ 报告: {report_file.name}")
    
    def build(self, build_type: str = "both", sign: bool = False, optimize: bool = False) -> bool:
        """执行完整构建流程"""
        print("\n" + "="*60)
        print("🚀 冰阅 Android APK 构建系统 (v2.1)")
        print("="*60)
        
        if not self.check_environment():
            print("\n❌ 环境检查失败")
            return False
        
        if not self.install_dependencies():
            print("\n❌ 依赖安装失败")
            return False
        
        if not self.init_cordova():
            print("\n❌ Cordova 初始化失败")
            return False
        
        success = True
        
        if build_type in ("debug", "both"):
            if not self.build_debug():
                success = False
        
        if build_type in ("release", "both"):
            if not self.build_release():
                success = False
        
        # 签名和优化
        if sign and success:
            apk_files = list(self.release_dir.glob("*release*unsigned.apk"))
            for apk in apk_files:
                self.sign_apk(apk.name)
        
        if optimize and success:
            apk_files = list(self.release_dir.glob("*release*.apk"))
            for apk in apk_files:
                if "optimized" not in apk.name:
                    self.optimize_apk(apk.name)
        
        self.generate_report()
        
        print("\n" + "="*60)
        if success:
            print("✅ 构建成功!")
            print(f"\n📂 输出目录: {self.release_dir}")
            apk_files = list(self.release_dir.glob("*.apk"))
            if apk_files:
                print("\n生成的 APK 文件:")
                for apk in sorted(apk_files, reverse=True)[:5]:
                    size = apk.stat().st_size / 1024 / 1024
                    print(f"  - {apk.name} ({size:.2f} MB)")
        else:
            print("❌ 构建失败")
        print("="*60)
        
        return success

def main():
    parser = argparse.ArgumentParser(
        description="冰阅 Android APK 构建工具 v2.1",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python3 build_tool.py --build both              # 构建 Debug 和 Release
  python3 build_tool.py --build debug             # 只构建 Debug
  python3 build_tool.py --build release --sign    # 构建并签名
  python3 build_tool.py --clean                   # 清理构建文件
        """
    )
    
    parser.add_argument(
        "--build",
        choices=["debug", "release", "both"],
        default="both",
        help="选择构建类型 (默认: both)"
    )
    
    parser.add_argument(
        "--sign",
        action="store_true",
        help="签名 Release APK (需要 jarsigner)"
    )
    
    parser.add_argument(
        "--optimize",
        action="store_true",
        help="优化 APK (需要 zipalign)"
    )
    
    parser.add_argument(
        "--clean",
        action="store_true",
        help="清理构建文件"
    )
    
    parser.add_argument(
        "--project",
        default=".",
        help="项目目录 (默认: 当前目录)"
    )
    
    args = parser.parse_args()
    
    builder = BingyuegeBuilder(args.project)
    
    if args.clean:
        builder.clean_build()
        return 0
    
    if builder.build(args.build, sign=args.sign, optimize=args.optimize):
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())
