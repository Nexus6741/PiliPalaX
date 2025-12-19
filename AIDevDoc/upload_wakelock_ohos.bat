@echo off
echo ========================================
echo 上传 wakelock_ohos 插件到 GitHub
echo ========================================

cd packages\wakelock_ohos

echo.
echo [1/6] 初始化 Git 仓库...
git init

echo.
echo [2/6] 添加远程仓库...
git remote add origin https://github.com/Nexus6741/wakelock_ohos.git

echo.
echo [3/6] 拉取远程仓库（如果有 README）...
git pull origin main --allow-unrelated-histories || git pull origin master --allow-unrelated-histories || echo 远程仓库为空，继续...

echo.
echo [4/6] 添加所有文件...
git add .

echo.
echo [5/6] 提交更改...
git commit -m "Initial commit: HarmonyOS wakelock plugin v1.0.0"

echo.
echo [6/6] 推送到 GitHub...
git push -u origin main || git push -u origin master

echo.
echo ========================================
echo 上传完成！
echo 仓库地址: https://github.com/Nexus6741/wakelock_ohos
echo ========================================

cd ..\..
pause
