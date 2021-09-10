---
title: nvm 高级命令指南
date: 2021-09-10 10:30:56
tags:
---

本文整理了一些 nvm 不常用、但非常有用的命令。主要分为以下几大类：

* reinstall-packages <version>            Reinstall global `npm` packages contained in <version> to current version

由于使用 npm install -g <package> 安装全局 npm 包，是安装到当前使用的版本的 node 下面，在安装新版本的 node 或者 切换 node 版本后，之前安装的全局 npm 包往往就不生效了，比如，切换 node 版本后，`yarn` 命令失效。

这时可以用 `nvm reinstall-packages <version>` 来将之前 node 下面所有的全局 npm 包都重新安装到当前使用的 node 版本中。

若想查看当前 node 版本中都安装了哪些全局 npm 包，可以使用 `npm ls -g` 来查看。
