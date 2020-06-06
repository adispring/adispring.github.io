---
title: Hexo-Init
date: 2018-09-09 08:54:45
tags:
---

## Hexo 踩坑指南

### 安装主题

我选用 [next](https://github.com/theme-next/hexo-theme-next) 主题，简洁、素雅

安装指南：

```bash
$ cd hexo
$ git clone https://github.com/theme-next/hexo-theme-next themes/next
```

### favicon 配置

需要在 `themes/next/_config.yml` 中对 favicon 进行配置，我的配置如下

```bash
# ---------------------------------------------------------------
# Site Information Settings
# ---------------------------------------------------------------

# To get or check favicons visit: https://realfavicongenerator.net
# Put your favicons into `hexo-site/source/` (recommend) or `hexo-site/themes/next/source/images/` directory.

# Default NexT favicons placed in `hexo-site/themes/next/source/images/` directory.
# And if you want to place your icons in `hexo-site/source/` root directory, you must remove `/images` prefix from pathes.

# For example, you put your favicons into `hexo-site/source/images` directory.
# Then need to rename & redefine they on any other names, otherwise icons from Next will rewrite your custom icons in Hexo.
favicon:
  small: /favicon.ico
  medium: /favicon.ico
  apple_touch_icon: /images/apple-touch-icon-next.ico
  safari_pinned_tab: /logo.svg
  #android_manifest: /images/manifest.json
  #ms_browserconfig: /images/browserconfig.xml
```

### 关于锚点失效问题

这是 [hexo-renderer-markdown-it](https://github.com/hexojs/hexo-renderer-markdown-it) 的一个 bug，但作者不想修复，认为是其他库的坑，所以我们要参考这个 [issue](https://github.com/hexojs/hexo-renderer-markdown-it/issues/40) ，手动到 node_modules 中修改该库，具体如下：

```js
'use strict';

module.exports = function (data, options) {
  var MdIt = require('markdown-it');
  var cfg = this.config.markdown;
  var opt = (cfg) ? cfg : 'default';
  var parser = (opt === 'default' || opt === 'commonmark' || opt === 'zero') ?
    new MdIt(opt) :
    new MdIt(opt.render);

  parser.use(require('markdown-it-named-headings')) // 只需要添加这行代码

  if (opt.plugins) {
    parser = opt.plugins.reduce(function (parser, pugs) {
      return parser.use(require(pugs));
    }, parser);
  }

  if (opt.anchors) {
    parser = parser.use(require('./anchors'), opt.anchors);
  }

  return parser.render(data.text);
};
```

### 自动化修复以上问题的脚本

写了一个自动化脚本，git pull 下我的博客备份后，自动安装、修复上述问题。

运行工程目录下的 `./hexo-init.sh`，内容如下：

```bash
#!/bin/bash

npm i hexo-cli -g

yarn

git clone https://github.com/theme-next/hexo-theme-next themes/next

# 修复锚点不生效问题
cp ./init_source/hexo-renderer-markdown-it/lib/renderer.js ./node_modules/hexo-renderer-markdown-it/lib/renderer.js

# 自动配置 favicon
cp ./init_source/next/_config.yml ./themes/next/_config.yml
```

### Git pull 下来的 Hexo 工程，hexo deploy 后将整个项目都 push 上去了

每次 git pull 备份的工程后，需要清理一下 hexo 工程，具体方法如下：

```bash
$ cd adispring.github.io
rm -rf .git .deploy_git hexo clean
```

