#!/bin/bash

echo "========================================"
echo "  通用加速代理 - 一键安装"
echo "========================================"
echo ""

# 创建工作目录
WORK_DIR="/opt/dl_proxy"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 生成 requirements.txt
cat > requirements.txt << 'EOF'
flask
requests
EOF

# 生成 main.py
cat > main.py << 'PYEOF'
# -*- coding: utf-8 -*-
import re
import requests
from flask import Flask, Response, redirect, request
from requests.utils import CaseInsensitiveDict
from urllib.parse import quote

HOST = '0.0.0.0'
PORT = 9011
size_limit = 1024 * 1024 * 1024 * 999

app = Flask(__name__)
CHUNK_SIZE = 1024 * 10
requests.sessions.default_headers = lambda: CaseInsensitiveDict()

INDEX_HTML = '''<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>通用加速代理</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, "Segoe UI", sans-serif;
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            color: #e0e0e0;
        }
        .container { width: 100%; max-width: 560px; padding: 20px; }
        h1 {
            font-size: 28px; font-weight: 700; text-align: center;
            background: linear-gradient(90deg, #667eea, #764ba2);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            margin-bottom: 8px;
        }
        .subtitle { text-align: center; color: #999; font-size: 14px; margin-bottom: 30px; }
        .input-box {
            display: flex; gap: 8px;
            background: rgba(255,255,255,0.06); border-radius: 12px;
            padding: 6px; border: 1px solid rgba(255,255,255,0.1);
        }
        .input-box input {
            flex: 1; padding: 12px 16px; font-size: 15px;
            background: transparent; border: none; outline: none;
            color: #fff;
        }
        .input-box input::placeholder { color: #666; }
        .input-box button {
            padding: 12px 24px; font-size: 15px; font-weight: 600;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: #fff; border: none; border-radius: 8px; cursor: pointer;
            transition: opacity 0.2s;
        }
        .input-box button:hover { opacity: 0.85; }
        .tips {
            margin-top: 28px; padding: 16px 20px;
            background: rgba(255,255,255,0.04); border-radius: 10px;
            border: 1px solid rgba(255,255,255,0.06);
        }
        .tips p { font-size: 13px; color: #888; line-height: 2; }
        .tips code {
            background: rgba(255,255,255,0.08); padding: 2px 6px;
            border-radius: 4px; font-size: 12px; color: #a8b2d1;
        }
        .tag {
            display: inline-block; font-size: 11px; padding: 2px 8px;
            border-radius: 4px; margin-right: 4px; font-weight: 600;
        }
        .tag-get { background: rgba(102,126,234,0.2); color: #667eea; }
        .tag-clone { background: rgba(118,75,162,0.2); color: #a78bfa; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚡ 通用加速代理</h1>
        <p class="subtitle">支持任意 HTTPS 链接加速访问</p>
        <form action="/" method="get">
            <div class="input-box">
                <input name="q" placeholder="粘贴完整URL，如 https://github.com/..." autofocus />
                <button type="submit">GO</button>
            </div>
        </form>
        <div class="tips">
            <p><span class="tag tag-get">下载</span> <code>http://本站/https://github.com/user/repo/archive/master.zip</code></p>
            <p><span class="tag tag-clone">克隆</span> <code>git clone http://本站/https://github.com/user/repo.git</code></p>
            <p><span class="tag tag-get">通用</span> <code>http://本站/https://任意网站/路径/文件</code></p>
        </div>
    </div>
</body>
</html>'''


@app.route('/')
def index():
    if 'q' in request.args:
        return redirect('/' + request.args.get('q'))
    return INDEX_HTML


@app.route('/favicon.ico')
def icon():
    return Response('', status=404)


@app.route('/<path:u>', methods=['GET', 'POST'])
def handler(u):
    u = u if u.startswith('http') else 'https://' + u
    if u.rfind('://', 3, 9) == -1:
        u = u.replace('s:/', 's://', 1)
    if not re.match(r'^https?://.+', u):
        return Response('Invalid URL.', status=403)
    u = quote(u, safe='/:@?&=#%+')
    return proxy(u)


def proxy(u, allow_redirects=False):
    headers = {}
    r_headers = dict(request.headers)
    for h in ('Host', 'Accept-Encoding'):
        r_headers.pop(h, None)
    try:
        url = u + request.url.replace(request.base_url, '', 1)
        if url.startswith('https:/') and not url.startswith('https://'):
            url = 'https://' + url[7:]
        r = requests.request(
            method=request.method, url=url,
            data=request.data, headers=r_headers,
            stream=True, allow_redirects=allow_redirects, timeout=300
        )
        headers = dict(r.headers)
        if 'Content-length' in r.headers and int(r.headers['Content-length']) > size_limit:
            return redirect(u + request.url.replace(request.base_url, '', 1))
        def generate():
            for chunk in r.iter_content(chunk_size=CHUNK_SIZE):
                if chunk:
                    yield chunk
        if 'Location' in r.headers:
            _location = r.headers.get('Location')
            if _location.startswith('http'):
                headers['Location'] = '/' + _location
            else:
                return proxy(_location, True)
        for h in ('Transfer-Encoding', 'Content-Encoding'):
            headers.pop(h, None)
        return Response(generate(), headers=headers, status=r.status_code)
    except Exception as e:
        headers['content-type'] = 'text/html; charset=UTF-8'
        return Response('server error ' + str(e), status=500, headers=headers)


app.debug = False
if __name__ == '__main__':
    print(f'通用代理已启动 | 监听: {HOST}:{PORT}')
    app.run(host=HOST, port=PORT)
PYEOF

# 生成 Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
EXPOSE 9011
CMD ["python", "main.py"]
EOF

# 停止旧容器
docker stop dl_proxy 2>/dev/null && docker rm dl_proxy 2>/dev/null

# 构建镜像
echo ""
echo ">> 构建 Docker 镜像..."
docker build -t dl_proxy .

if [ $? -ne 0 ]; then
    echo "错误: 镜像构建失败！"
    exit 1
fi

# 启动容器
echo ">> 启动容器..."
docker run -d \
    --name dl_proxy \
    -p "0.0.0.0:9011:9011" \
    --restart=always \
    dl_proxy

if [ $? -eq 0 ]; then
    SERVER_IP=$(curl -s4 --max-time 5 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "本机IP")
    echo ""
    echo "========================================"
    echo "  ✅ 部署成功！"
    echo "  服务地址: http://${SERVER_IP}:9011"
    echo ""
    echo "  使用方式："
    echo "  wget http://${SERVER_IP}:9011/https://github.com/user/repo/archive/master.zip"
    echo "  git clone http://${SERVER_IP}:9011/https://github.com/user/repo.git"
    echo "========================================"
else
    echo "错误: 容器启动失败！"
    exit 1
fi
