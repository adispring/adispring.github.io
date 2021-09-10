---
title: Hexo Workflow
---
Welcome to [Hexo](https://hexo.io/)! This is your very first post. Check [documentation](https://hexo.io/docs/) for more info. If you get any problems when using Hexo, you can find the answer in [troubleshooting](https://hexo.io/docs/troubleshooting.html) or you can ask me on [GitHub](https://github.com/hexojs/hexo/issues).

## Quick Start

### Create a new post

``` bash
$ hexo new "My New Post"
```

More info: [Writing](https://hexo.io/docs/writing.html)

### Run server

``` bash
$ hexo server
```

More info: [Server](https://hexo.io/docs/server.html)

### Generate static files

``` bash
$ hexo generate
```

More info: [Generating](https://hexo.io/docs/generating.html)

### Deploy to remote sites

``` bash
$ hexo deploy
```

### Generate & Deploy together

``` bash
$ hexo d -g
```

More info: [Deployment](https://hexo.io/docs/deployment.html)

### Hexo 自动化部署

* 官方自动化部署文档 -- Hexo + Travis: https://hexo.io/docs/github-pages.html
* 空白页问题的解决方案：http://magicse7en.github.io/2016/03/27/travis-ci-auto-deploy-hexo-github/

自动化部署工作流：

本地开发使用 hexo-source 分支，开发完成后，推导 github 仓库，会触发自动化部署，自动部署在 master 分支上生成最新的文档并部署。
