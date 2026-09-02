# LGNewUi Docker 部署说明

## 环境要求

- Docker 20.10+
- Docker Compose 1.29+
- 适用于 1Panel 或飞牛等面板环境

## 文件清单

```
.
├── Dockerfile
├── docker-compose.yml
└── loaders/
    └── ixed.8.0.lin
```

## 部署步骤

### 前提需要

选择或创建一个项目目录（注意不要创建名为 LGNewUi 的目录），进入该目录后执行：

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Freewind72/jsbat@main/LGNewUi-Docker/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

安装脚本会自动下载并解压 Docker 配置文件到当前目录，然后构建并启动容器。

### 查看状态

```bash
docker ps | grep lgnewui-zeph
docker logs lgnewui-zeph
```

### 访问测试

```bash
curl -I http://localhost:8081
```

## 更新部署

更新核心代码后重新构建：

```bash
cd /opt/your-project

docker stop lgnewui-zeph
docker rm lgnewui-zeph
docker-compose build
docker-compose up -d
```

**注意：** 重新构建不会重置已挂载的持久化数据（uploads、Lovefolder、storage 子目录等）。

## 持久化说明

以下目录通过 bind mount 持久化到宿主机：

| 宿主机路径 | 容器内路径 | 用途 |
|-----------|-----------|------|
| `/opt/your-project/uploads` | `/var/www/html/uploads` | 用户上传文件 |
| `/opt/your-project/Lovefolder` | `/var/www/html/Lovefolder` | 资源文件 |
| `/opt/your-project/storage/updates` | `/var/www/html/storage/updates` | 更新包 |
| `/opt/your-project/storage/logs` | `/var/www/html/storage/logs` | 日志 |
| `/opt/your-project/storage/cache` | `/var/www/html/storage/cache` | 缓存 |
| `/opt/your-project/storage/runtime` | `/var/www/html/storage/runtime` | 运行时数据 |
| `/opt/your-project/storage/weather_api` | `/var/www/html/storage/weather_api` | 天气 API 数据 |
| `/opt/your-project/storage/jobs` | `/var/www/html/storage/jobs` | 任务队列 |
| `/opt/your-project/storage/packages` | `/var/www/html/storage/packages` | 扩展包 |
| `/opt/your-project/storage/staging` | `/var/www/html/storage/staging` | 临时文件 |
| `/opt/your-project/storage/backups` | `/var/www/html/storage/backups` | 数据库备份 |

**未挂载目录：** `storage/license/` 保留在容器内，随镜像更新而更新。

## 网络配置

默认使用外部网络 `1panel-network`。若使用其他网络，请修改 `docker-compose.yml`：

```yaml
networks:
  your-network-name:
    external: true
```

## 反向代理

若通过域名访问，建议在 Nginx 中配置反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 常见问题

### 1. 端口冲突

若 8081 端口被占用，修改 `docker-compose.yml`：

```yaml
ports:
  - "8082:80"
```

### 2. 权限问题

容器启动时会自动设置目录权限。若手动修改宿主机目录权限导致异常，可执行：

```bash
docker exec lgnewui-zeph chown -R www-data:www-data /var/www/html/uploads /var/www/html/Lovefolder /var/www/html/storage
docker exec lgnewui-zeph chmod -R 775 /var/www/html/uploads /var/www/html/Lovefolder /var/www/html/storage
```

### 3. 数据库配置

首次安装完成后，建议将数据库配置文件挂载为只读：

```yaml
volumes:
  - /opt/your-project/Config_DB.php:/var/www/html/panel/Config_DB.php:ro
```

### 4. 安装锁文件

安装完成后，建议挂载安装锁文件：

```yaml
volumes:
  - /opt/your-project/install.lock:/var/www/html/install/install.lock:ro
```

## 技术规格

- **基础镜像：** php:8.0-apache
- **PHP 扩展：** bcmath, exif, gettext, gmp, gd, imagick, intl, mysqli, opcache, pcntl, pdo_mysql, shmop, soap, sockets, sysvsem, zip
- **系统工具：** ffmpeg, mysqldump, curl
- **加密支持：** SourceGuardian Loader
- **容器名：** lgnewui-zeph
- **镜像名：** lgnewui_zeph
- **暴露端口：** 80（映射到宿主机 8081）