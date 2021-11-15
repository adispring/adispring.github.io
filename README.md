# Hexo 博客写作与部署过程

## 本地开发

```bash
# 1. clone github 仓库
git clone origin git@github.com:adispring/adispring.github.io.git

# 2. 切换到写作分支：hexo-source 
gco hexo-source

# 3. 写作...

# 4. 写作完毕，push 到远端，自动部署
git push origin hexo-source:hexo-source
```

### 写作过程

```bash
# 1. 创建新文章
hexo new '[文章题目]'
```

## 远端自动部署

将 hexo-source 分支 push 到 github 仓库后，会触发自动化部署，Travis CI 会帮忙在 master 分支上生成最新的文档，部署。
