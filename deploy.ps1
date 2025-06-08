# 确保脚本抛出遇到的错误
$ErrorActionPreference = "Stop"

# 生成静态文件
pnpm docs:build

# 进入生成的文件夹
Set-Location -Path "src/.vuepress/dist"

# 初始化 Git 仓库
git init

# 添加所有文件到暂存区
git add -A

# 提交更改
git commit -m 'deploy'

# 如果发布到 https://<USERNAME>.github.io/<REPO>
git push -f https://github.com/zhouxzh/FPGA-course.git master:deploy

# 返回上一级目录
Set-Location -Path "../../.."