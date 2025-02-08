#!/usr/bin/env sh 
set -e 
pnpm run docs:build 
cd dist 
git init 
git add -A 
git commit -m 'deploy' 
git push -f https://github.com/zhouxzh/FPGA-course.git master:gh-pages 
cd -