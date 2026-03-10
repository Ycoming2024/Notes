# Backend Deployment (Ubuntu + PM2 + Nginx)

## 1) Prepare server

```bash
sudo apt update
sudo apt install -y curl git nginx
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm i -g pm2
node -v
npm -v
```

## 2) Upload code

```bash
sudo mkdir -p /opt/newProject
sudo chown -R $USER:$USER /opt/newProject
cd /opt/newProject
git clone <your-repo-url> .
```

If code already exists, update:

```bash
cd /opt/newProject
git pull
```

## 3) Configure env

```bash
cd /opt/newProject/server
cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL="file:/opt/newProject/server/data/prod.db"
```

## 4) Install and build

```bash
cd /opt/newProject/server
npm ci
npx prisma generate
npx prisma migrate deploy
npm run build
```

## 5) Start backend with PM2

```bash
cd /opt/newProject/server
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

Check status:

```bash
pm2 ls
pm2 logs notes-api --lines 100
```

## 6) Reverse proxy (Nginx)

Create `/etc/nginx/sites-available/notes-api`:

```nginx
server {
  listen 80;
  server_name _;

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

Enable and reload:

```bash
sudo ln -sf /etc/nginx/sites-available/notes-api /etc/nginx/sites-enabled/notes-api
sudo nginx -t
sudo systemctl reload nginx
```

## 7) API check

```bash
curl http://127.0.0.1:3000/v1
```

If no root route, test one existing API route in your project instead.

