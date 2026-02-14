# ⚡ DL-Proxy - 通用加速代理

基于 [hunshcn/gh-proxy](https://github.com/hunshcn/gh-proxy) 二次开发，扩展为支持任意 HTTPS 链接的通用反向代理，适用于网络受限环境下加速下载 GitHub、Docker Hub 等海外资源。

## 功能特点

- 🌍 **通用代理** — 支持任意 HTTPS 链接，不限于 GitHub
- 🐳 **一键 Docker 部署** — 一条命令即可完成安装
- 📦 **端口固定 9011** — 开箱即用，无需额外配置
- 🔄 **自动重启** — 容器异常退出后自动恢复

## 与原版区别

| | [gh-proxy](https://github.com/hunshcn/gh-proxy) | DL-Proxy |
|---|---|---|
| 代理范围 | 仅 GitHub 相关域名 | **任意 HTTPS 链接** |
| URL 验证 | 6 个正则严格匹配 | 仅验证合法 URL |
| 部署方式 | 手动 | **一键 Docker 部署** |

## 快速安装

```bash
bash <(curl -sL https://raw.githubusercontent.com/Assute/dl_proxy/main/dl_proxy.sh)
```

安装完成后会自动显示服务器公网 IP 和使用方式。

## 使用方式

在任意 URL 前拼接代理地址即可：

```bash
# 下载文件
wget http://你的IP:9011/https://github.com/user/repo/archive/master.zip

# 克隆仓库
git clone http://你的IP:9011/https://github.com/user/repo.git

# 下载并执行脚本
bash <(curl -sL http://你的IP:9011/https://raw.githubusercontent.com/user/repo/main/install.sh)

# 代理任意网站
curl http://你的IP:9011/https://example.com/path/to/file
```

## 架构说明

```
客户端 → DL-Proxy (本机:9011) → 目标网站
```

DL-Proxy 部署在**可直接访问海外**的服务器上，客户端通过它中转下载。

## 搭配 CN-Proxy 使用（可选）

如果客户端也无法直接访问 DL-Proxy 所在服务器，可以加一层国内中继：

```
客户端(A) → CN-Proxy(国内:9010) → DL-Proxy(海外:9011) → 目标网站
```

CN-Proxy 会自动检测脚本文件（`.sh`、`.py` 等），将脚本内的所有 HTTPS 链接替换为代理链接。

详见 [CN-Proxy](https://github.com/Assute/cn_proxy)

## 管理命令

```bash
# 查看日志
docker logs -f dl_proxy

# 重启服务
docker restart dl_proxy

# 停止服务
docker stop dl_proxy

# 卸载
docker stop dl_proxy && docker rm dl_proxy && docker rmi dl_proxy
```

## 系统要求

- Linux 服务器
- Docker 已安装
- 服务器可访问目标网站

## 致谢

- [hunshcn/gh-proxy](https://github.com/hunshcn/gh-proxy) — 原版 GitHub 文件加速项目

## License

MIT
