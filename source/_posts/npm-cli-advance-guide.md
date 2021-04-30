---
title: npm 命令高级指南
date: 2021-04-30 11:23:56
tags:
---

本文整理了一些 npm 不常用、但非常有用的命令。主要分为以下几大类：

* 查看 npm 源(registry) 上的 npm 包信息
  * npm view

* 开发 npm 包时，用到的命令
  * npm publish
  * npm pack
  * npm link & npm unlink
  * npm set-script

* 查看已安装的 npm 包的本地信息
  * npm ls
  * npm edit
  * npm explore
  * npm explain | npm why

* 浏览器查看 npm 包信息
  * npm docs
  * npm repo

* 使用 npm 包开发其他项目时，用到的命令
  * npm outdated
  * npm update

* 其他 npm 命令
  * npm config
  * npm bin
  * npm completion


# 查看 npm 源(registry) 上的 npm 包信息

* npm view: 最为灵活、最为强大的 查看 npm 包信息的命令；

由于 `npm view` 太灵活，所以需要单独一小节进行讲解。

## npm view

查看 npm 源上包的信息

```bash
npm view [<@scope>/]<name>[@<version>] [<field>[.<subfield>]...]

aliases: info, show, v
```

### 查看包的基本信息

```bash
npm view <pkg>
```

示例：

```bash
› npm view ramda

ramda@0.27.1 | MIT | deps: none | versions: 52
A practical functional library for JavaScript programmers.
https://ramdajs.com/

dist
.tarball: http://r.npm.sankuai.com/ramda/download/ramda-0.27.1.tgz
.shasum: 66fc2df3ef873874ffc2da6aa8984658abacf5c9

maintainers:
- aromano <aromano@preemptsecurity.com>
- bradcomp <notpmoc84@hotmail.com>
- ...

dist-tags:
0.2.0: 0.2.0          es-rc: 0.24.1-es.rc3  latest: 0.27.1

published 9 months ago by davidchambers <dc@davidchambers.me>
```

### 更加灵活的查看包的详细信息

```bash
npm view <pkg>@<version> <field>[.<subfield>]...
```

#### 查看包的依赖

```bash
› npm view http-server dependencies
{
  'basic-auth': '^1.0.3',
  colors: '^1.4.0',
  corser: '^2.0.1',
  ecstatic: '^3.3.2',
  'http-proxy': '^1.18.0',
  minimist: '^1.2.5',
  opener: '^1.5.1',
  portfinder: '^1.0.25',
  'secure-compare': '3.0.1',
  union: '~0.5.0'
}
```

#### 查看包的最新版本

```bash
› npm view ramda version
0.27.1
```

#### 查看包发布的所有版本

```bash
› npm view ramda versions
[
  '0.1.0',         '0.1.1',         '0.1.2',
  '0.1.4',         '0.1.5',         '0.2.0',
  '0.2.1',         '0.2.2',         '0.2.3',
  '0.2.4',         '0.3.0',         '0.4.0',
  '0.4.1',         '0.4.2',         '0.4.3',
  '0.5.0',         '0.6.0',         '0.7.0',
  '0.7.1',         '0.7.2',         '0.8.0',
  '0.9.0',         '0.9.1',         '0.10.0',
  '0.11.0',        '0.12.0',        '0.13.0',
  '0.14.0',        '0.15.0',        '0.15.1',
  '0.16.0',        '0.17.0',        '0.17.1',
  '0.18.0',        '0.19.0',        '0.19.1',
  '0.20.0',        '0.20.1',        '0.21.0',
  '0.22.0',        '0.22.1',        '0.23.0',
  '0.24.0',        '0.24.1-es.rc1', '0.24.1-es.rc2',
  '0.24.1-es.rc3', '0.24.1',        '0.25.0',
  '0.26.0',        '0.26.1',        '0.27.0',
  '0.27.1'
]
```

#### 查看指定版本范围内的包的发布情况

查看自 0.25.0 以来，所有版本 ramda 包的信息

```bash
npm view ramda@'>=0.25.0'
```

#### 查看 npm 包官网地址

```bash
npm view ramda homepage
```

#### 查看 npm 包仓库地址

```bash
npm view ramda repository.url
```

#### 通过 shell 脚本，组合出灵活的查询命令

可以通过一些 Shell 脚本轻松查看有关依赖项的信息。例如，要查看有关ronn所依赖的opts版本的所有数据，如下所示：

```bash
npm view opts@$(npm view ronn dependencies.opts)
```

更多 `npm view` 的高级用法，可以查看 [npm view 官方文档](https://docs.npmjs.com/cli/v7/commands/npm-view)

# 开发 npm 包涉及的命令

* npm publish: 将包发布到 npm 源(registry) 上去;

* npm pack: 打包;

* npm link: 将当前 package 文件夹软链到全局 npm 环境中;

* npm unlink: 断开全局软链时，其实就是 npm uninstall 的别名;

* npm set-script: 在 package.json 的 `"scripts"` 字段中设置任务;

## npm publish -- 发包

将包发布到 npm 源(registry) 上去。

### 模拟发包

```bash
npm publish --dry-run
```

`npm publish --dry-run` 只是模拟发包，并不会真正发包。会将发包过程中的所有信息都打印出来，用作发包前进行信息确认。也可以使用 `npm pack --dry-run`

### 发布的包中包含的文件

要查看软件包中将包含的内容，请运行 `npx npm-packlist`。默认情况下，所有文件都包括在内，但以下情况除外：

* 始终包含与软件包安装和分发相关的某些文件。例如，`package.json`，`README.md`，`LICENSE` 等。

* 如果 `package.json` 中有一个 `"files"` 列表字段，则仅包含 `"files"` 指定的文件。（如果指定了目录，则将遵循相同的忽略规则，以递归方式遍历目录并包含目录的内容。）

* 如果存在 `.gitignore` 或 `.npmignore` 文件，则其中的被忽略文件以及所有子目录都将从软件包中排除。如果两个文件都存在，则将忽略 `.gitignore`，而仅使用 `.npmignore`。

  `.npmignore` 文件遵循与 `.gitignore` 文件相同的模式规则

* **需要特别注意的是：如果文件匹配某些模式，则除非明确将其添加到 `package.json` 的 "files" 列表中，否则将永远不会将其包括在内，或者在 `.npmignore` 或 `.gitignore` 文件中使用 `!` ，来强制包含需要发布的文件**。
  
  例如，npm 发包，默认是会忽略 `.npmrc` 文件的，如果我确实需要将 `.npmrc` 包含进发布的包中，则需要使用在 `.npmignore` 或 `.gitignore` 中写入规则 `!.npmrc`，`!.npmrc` 表示强制包含 `.npmrc`。

* 符号链接永远不会包含在 npm 软件包中。

有关已发布的软件包中包含的内容以及如何构建该软件包的详细信息，请查看 [开发者须知](https://docs.npmjs.com/cli/v7/using-npm/developers) 。

## npm pack -- 打包

```bash
npm pack [[<@scope>/]<pkg>...] [--dry-run]
```

一般会用到 `npm pack --dry-run` ，看一下即将发布的包的打包情况。加了 `--dry-run` 会后，命令不会真正的执行，只是把之间结果打印出来，以供调试使用。

## npm link & npm unlink - 本地开发

本地调试利器

### npm link

将当前 package 文件夹软链到全局 npm 环境中。开发某个 npm 包时，本地调试非常好用。避免了在开发过程中不断重复发包的困扰。

npm link 分两步：

* 软链当前的 package；

* 使用软链过的 package；

如下所示：

```bash
cd ~/projects/node-redis    # go into the package directory
npm link                    # creates global link
cd ~/projects/node-bloggy   # go into some other package directory.
npm link redis              # link-install the package
```

### npm unlink

当本地调试完成，想要断开全局软链时，运行下面命令：

```bash
npm unlink <pkg> -g
```

`npm unlink` 会将 <pkg> 从全局的 npm 环境中移除（断开软链）。

注：`npm unlink` 其实是 `npm uninstall` 的别名，所以运行 `npm unlink <pkg> -g` 等价于 `npm uninstall <pkg> -g` 。

### npm set-script

在 package.json 的 `"scripts"` 字段中设置任务。

```bash
npm set-script [<script>] [<command>]
```

如果开发的 npm 包在安装时，需要动态修改项目中 `package.json` 文件的 `"scripts"` ，则可以使用该命令进行设置。

示例:

```bash
npm set-script start "http-server ."
```

```json
{
  "name": "my-project",
  "scripts": {
    "start": "http-server .",
    "test": "some existing value"
  }
}
```

向 `"scripts"` 中添加 `"start"` 脚本。

# 查看已安装的 npm 包的本地信息

* npm ls: 列出安装的 packages，或者指定 package 的依赖树；

* npm edit: 使用默认的编辑器打开当前项目中指定的 npm 包；

* npm explore: 进入指定的被安装的 npm 包的目录；

* npm explain | npm why: 解释 packages 被安装的原因。主要是把指定包的依赖链条打印出来；

## npm ls

列出安装的 packages。

```bash
npm ls [<pkg> -g]
```

### 打印出当前项目已安装的首层 packages

```bash
npm ls
```

### 所有的依赖以依赖树的形式打印出来

```bash
npm ls -all
```

当使用 `--all` 时，会将所有的依赖以依赖树的形式打印出来。

### 打印全局安装的 packages

```bash
npm ls -g
```

### 打印指定 packages 的安装情况

```bash
npm ls name@version-range
```

`npm ls name@version-range` 可以以结构树的形式打印出指定 package 在项目中的安装情况。

也可以使用 `npm explain` 查看指定的 package 为什么会被安装，作用相当于 `npm ls` ，只不过展示的顺序是反向的。

```bash
npm explain name
```

## npm edit

使用默认的编辑器，直接打开当前项目已经安装的 package 的文件夹。可以省去手动到 node_modules 中查找 package 的麻烦。

```bash
npm edit <pkg>
```

例如：

```bash
npm edit prettier
```

会打开当前项目下的 `./node_modules/prettier` 目录。

### 指定默认的编辑器，修改 `$EDITOR` 变量

```bash
echo export EDITOR="emacsclient -t" >> ~/.zshrc
```

## npm explore

在命令行中，进入指定的被安装的 package 文件夹中。

```bash
npm explore <pkg> [ -- <command>]
```

示例：

1. 进入当前项目中某 package 的目录

```bash
// 进入当前项目中安装的 prettier 目录
npm explore prettier

pwd
// project/node_modules/prettier
```

2. 进入全局安装的某 package 目录

```bash
// 进入全局安装的 prettier 目录
npm explore prettier -g

pwd
// /Users/wangzengdi/.nvm/versions/node/v14.15.4/lib/node_modules/prettier
```

## npm explain | npm why

解释已安装的 packages，被安装的原因。

会将当前指定包的依赖关系打印出来（哪些包依赖的指定的包），可以用于解释为什么一个依赖为什么会被安装多次。

```bash
npm explain <folder | specifier>

alias: why
```

例如：

```bash
› npm explain eslint

eslint@7.25.0 dev
node_modules/eslint
  dev eslint@"^7.25.0" from the root project
  peer eslint@">= 4.12.1" from babel-eslint@10.1.0
  node_modules/babel-eslint
    dev babel-eslint@"^10.1.0" from the root project
  peer eslint@">=7.0.0" from eslint-config-prettier@8.3.0
  node_modules/eslint-config-prettier
    dev eslint-config-prettier@"^8.3.0" from the root project
  ...
```

表示当前项目在 devDependencies 中安装了 7.25.0 版本的 eslint，安装的位置为 `node_modules/eslint` 。后面的部分表明是哪些包的依赖，导致了 eslint 的安装。

# 浏览器查看 npm 包信息

* npm docs | npm home: 在浏览器中打开 npm 包官网；

* npm repo: 在浏览器中打开 npm 包仓库地址；

## npm docs

在浏览器中打开指定 npm 包的官方网站。

```bash
npm docs [pakname]

aliases: home
```

例如 

```bash
# 会打开 react 官网: https://reactjs.org/
npm docs react

# 会打开 ramda 官网: https://ramdajs.com/
npm docs ramda
```

npm 的官方网站一般写在 package.json 中的 "homepage" 字段中。

## npm repo

在浏览器中打开指定 npm 包的仓库（一般为 github 仓库）地址。

```bash
npm repo [<pkgname> [<pkgname> ...]]
```

例如

```bash
# 会打开 ramda github 仓库: https://github.com/ramda/ramda
npm repo ramda
```

# 使用 npm 包开发其他项目时，用到的命令

## npm outdated vs npm update

### npm outdated

查看项目中是否存在过期的 packages，或者指定的 packages 是否过期

```bash
npm outdated [<pkg> ...]
```

举例

```bash
› npm outdated
Package       Current  Wanted  Latest  Location                   Depended by
semver-regex    3.1.2   3.1.2   4.0.0  node_modules/semver-regex  fe.cli
```

在某一项目下运行 `npm outdated`，便可以列出当前项目中所有已经过期的依赖。

如上所示，semver-regex 已经过期了，当前版本为 `3.1.2`，最新版本为 `4.0.0`。

想要查看 package 的详细信息，可以使用`npm view <pkg>`，如查看 semver-regex： `npm view semver-regex`。

#### 查看全局已经过期的 package

```bash
npm outdated -g
```

### npm update & npm upgrade

更新 packages，npm update 会将 package 更新到当前已发布的 **最新版本**。

```bash
npm update [-g] [<pkg>...]

aliases: up, upgrade
```

在上文中，我们已经介绍了使用 `npm outdated` 查看过期的 packages。本段将介绍如何使用 `npm update` 更新过期的 packages

#### 更新当前项目中所有过期的项目

```bash
npm update
```

#### 更新全局的过期项目

```bash
npm update -g
```

#### 更新指定的 packages

```bash
npm update pkg1 pkg2 ...
```

# 其他 npm 命令

* npm config: npm 配置

* npm bin: 打印 npm 可执行命令 bin 的文件夹

* npm completion: npm 补全脚本


## npm config

npm 配置。用于列出当前 npm 环境的配置信息，或管理 npm 配置文件，一般是 .npmrc。

### 列出当前的 npm 配置

```bash
npm config list

# 列出详细配置
npm config list -l
```

## npm bin

打印 npm 可执行命令 bin 的文件夹

```bash
npm bin [-g | --global]
```

## npm completion

npm 补全命令脚本， 可以通过下列命令将命令补全脚本注入到 .bashrc 或 .zshrc 中，这样即可以在终端的任何地方使用。

```bash
npm completion >> ~/.bashrc
npm completion >> ~/.zshrc
```

