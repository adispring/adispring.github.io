#!/bin/bash

npm i hexo-cli -g

yarn

rm -rf ./themes/next
git clone https://github.com/theme-next/hexo-theme-next themes/next

# 修复锚点不生效问题
cp ./init_source/hexo-renderer-markdown-it/lib/renderer.js ./node_modules/hexo-renderer-markdown-it/lib/renderer.js

# 自动配置 favicon
cp ./init_source/next/_config.yml ./themes/next/_config.yml
