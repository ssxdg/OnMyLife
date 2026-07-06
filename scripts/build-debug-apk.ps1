$ErrorActionPreference = "Stop"

# 使用项目本地的高德配置文件打包调试 APK。
# 真实 Key 存放在 env/amap.local.json，该文件已被 .gitignore 忽略，避免提交到远程仓库。
$flutter = "C:\tools\flutter\bin\flutter.bat"
$amapConfigFile = "env/amap.local.json"

if (-not (Test-Path $flutter)) {
  throw "未找到 Flutter 命令：$flutter"
}

if (-not (Test-Path $amapConfigFile)) {
  throw "未找到高德本地配置文件：$amapConfigFile"
}

& $flutter build apk --debug --dart-define-from-file=$amapConfigFile
