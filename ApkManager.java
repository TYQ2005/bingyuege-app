import java.io.*;
import java.nio.file.*;
import java.util.*;

/**
 * 冰阅 APK 管理工具
 * =================
 * 用于 APK 签名、验证和管理
 */

public class ApkManager {
    
    private static final String VERSION = "2.0";
    private static final String APP_NAME = "冰阅 (Bingyuege)";
    
    static class ApkInfo {
        String path;
        long size;
        String md5;
        String buildTime;
        
        ApkInfo(String path) throws IOException {
            this.path = path;
            this.size = Files.size(Paths.get(path));
            this.md5 = calculateMD5(path);
            this.buildTime = new java.util.Date().toString();
        }
        
        @Override
        public String toString() {
            return String.format("APK 信息:\n" +
                    "  文件: %s\n" +
                    "  大小: %.2f MB\n" +
                    "  MD5: %s\n" +
                    "  时间: %s",
                    path,
                    size / 1024.0 / 1024.0,
                    md5,
                    buildTime);
        }
    }
    
    /**
     * 计算文件 MD5
     */
    private static String calculateMD5(String filename) throws IOException {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
            byte[] bytes = Files.readAllBytes(Paths.get(filename));
            md.update(bytes);
            
            StringBuilder sb = new StringBuilder();
            for (byte b : md.digest()) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return "N/A";
        }
    }
    
    /**
     * 分析 APK 信息
     */
    public static void analyzeApk(String apkPath) throws IOException {
        ApkInfo info = new ApkInfo(apkPath);
        System.out.println(info);
        
        // 检查 AndroidManifest.xml
        checkAPKStructure(apkPath);
    }
    
    /**
     * 检查 APK 结构
     */
    private static void checkAPKStructure(String apkPath) throws IOException {
        System.out.println("\n验证 APK 结构...");
        
        // 使用 ZipFile 检查结构
        try (java.util.zip.ZipFile zip = new java.util.zip.ZipFile(apkPath)) {
            boolean hasManifest = zip.getEntry("AndroidManifest.xml") != null;
            boolean hasResources = zip.getEntry("resources.arsc") != null;
            boolean hasClasses = zip.getEntry("classes.dex") != null;
            
            System.out.println("  ✓ AndroidManifest.xml: " + (hasManifest ? "存在" : "缺失"));
            System.out.println("  ✓ resources.arsc: " + (hasResources ? "存在" : "缺失"));
            System.out.println("  ✓ classes.dex: " + (hasClasses ? "存在" : "缺失"));
            
            // 列出所有文件
            System.out.println("\n  文件列表:");
            zip.stream()
                .filter(e -> e.getName().endsWith(".dex") || 
                           e.getName().endsWith(".so") ||
                           e.getName().endsWith(".class"))
                .forEach(e -> System.out.println("    - " + e.getName()));
        }
    }
    
    /**
     * 生成签名命令
     */
    public static void generateSignCommand(String apkPath, String keystorePath) {
        System.out.println("生成 APK 签名命令:");
        System.out.println();
        
        // 创建密钥库
        System.out.println("1. 创建签名密钥库 (如果还没有):");
        System.out.println("   keytool -genkey -v -keystore " + keystorePath + 
                          " -keyalg RSA -keysize 2048 -validity 10000 -alias bingyuege");
        System.out.println();
        
        // 签名 APK
        String signedApk = apkPath.replace(".apk", "-signed.apk");
        System.out.println("2. 签名 APK:");
        System.out.println("   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \\");
        System.out.println("     -keystore " + keystorePath + " \\");
        System.out.println("     " + apkPath + " bingyuege");
        System.out.println();
        
        // 优化 APK
        System.out.println("3. 优化 APK (zipalign):");
        System.out.println("   zipalign -v 4 " + apkPath + " " + signedApk);
        System.out.println();
        
        // 验证签名
        System.out.println("4. 验证签名:");
        System.out.println("   jarsigner -verify -verbose " + signedApk);
    }
    
    /**
     * 生成构建报告
     */
    public static void generateBuildReport(String releaseDir) throws IOException {
        System.out.println("\n📊 构建报告\n");
        System.out.println("==================================================");
        System.out.println("冰阅 Android APK 构建报告");
        System.out.println("生成时间: " + new java.util.Date());
        System.out.println("版本: " + VERSION);
        System.out.println("==================================================");
        System.out.println();
        
        Path releasePath = Paths.get(releaseDir);
        if (!Files.exists(releasePath)) {
            System.out.println("❌ 发布目录不存在: " + releaseDir);
            return;
        }
        
        System.out.println("生成的 APK 文件:");
        Files.walk(releasePath)
            .filter(p -> p.toString().endsWith(".apk"))
            .forEach(p -> {
                try {
                    long size = Files.size(p);
                    System.out.printf("  ✓ %s (%.2f MB)\n",
                            p.getFileName(),
                            size / 1024.0 / 1024.0);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
        
        // 统计信息
        System.out.println("\n系统信息:");
        System.out.println("  Java: " + System.getProperty("java.version"));
        System.out.println("  OS: " + System.getProperty("os.name"));
        System.out.println("  用户: " + System.getProperty("user.name"));
    }
    
    /**
     * 打印使用说明
     */
    public static void printUsage() {
        System.out.println("┌─────────────────────────────────────────────┐");
        System.out.println("│  " + APP_NAME + " APK 管理工具 v" + VERSION + "  │");
        System.out.println("└─────────────────────────────────────────────┘");
        System.out.println();
        System.out.println("用法:");
        System.out.println("  java ApkManager <command> [options]");
        System.out.println();
        System.out.println("命令:");
        System.out.println("  analyze <apk_path>        分析 APK 信息");
        System.out.println("  sign <apk_path> <keystore> 生成签名命令");
        System.out.println("  report <release_dir>      生成构建报告");
        System.out.println("  help                      显示此帮助");
        System.out.println();
        System.out.println("示例:");
        System.out.println("  java ApkManager analyze app-release-unsigned.apk");
        System.out.println("  java ApkManager sign app.apk .keystore");
        System.out.println("  java ApkManager report release/");
    }
    
    /**
     * 主函数
     */
    public static void main(String[] args) {
        if (args.length == 0) {
            printUsage();
            return;
        }
        
        String command = args[0];
        
        try {
            switch (command) {
                case "analyze":
                    if (args.length < 2) {
                        System.err.println("❌ 错误: 需要 APK 文件路径");
                        break;
                    }
                    analyzeApk(args[1]);
                    break;
                
                case "sign":
                    if (args.length < 2) {
                        System.err.println("❌ 错误: 需要 APK 文件路径");
                        break;
                    }
                    String keystore = args.length >= 3 ? args[2] : ".keystore";
                    generateSignCommand(args[1], keystore);
                    break;
                
                case "report":
                    if (args.length < 2) {
                        System.err.println("❌ 错误: 需要发布目录路径");
                        break;
                    }
                    generateBuildReport(args[1]);
                    break;
                
                case "help":
                case "-h":
                case "--help":
                    printUsage();
                    break;
                
                default:
                    System.err.println("❌ 未知命令: " + command);
                    printUsage();
                    System.exit(1);
            }
        } catch (Exception e) {
            System.err.println("❌ 错误: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
