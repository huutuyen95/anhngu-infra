# anhngu-infra

Repo điều phối, chạy toàn bộ hệ thống (backend + frontend + MySQL + Redis) bằng **1 lệnh**.
`backend/` và `frontend/` là **git submodule** trỏ tới 2 repo riêng.

## Lần đầu clone (kèm submodule)

```bash
git clone --recurse-submodules git@github.com:<account>/anhngu-infra.git
cd anhngu-infra

# nếu lỡ clone thiếu submodule:
git submodule update --init --recursive
```

## Cấu hình

```bash
cp .env.example .env                       # biến cho docker-compose
cp env/backend.env.example env/backend.env # env cho Laravel
```

## Chạy (dev)

```bash
make up          # = docker compose up -d --build
make fresh       # migrate:fresh --seed (dữ liệu mẫu, lần đầu)
make logs
```

- Frontend: http://localhost:3000
- API:      http://localhost:8000/api/v1
- MySQL:    localhost:3306 · Redis: localhost:6379

## Thêm submodule (chỉ làm 1 lần khi khởi tạo infra)

```bash
git submodule add git@github.com:<account>/anhngu-backend.git backend
git submodule add git@github.com:<account>/anhngu-frontend.git frontend
git commit -m "add submodules"
```

## Cập nhật code submodule về mới nhất

```bash
git submodule update --remote --merge
```

## Kiến trúc container

```
        :3000                :8000
   ┌───────────┐        ┌───────────┐   fastcgi   ┌──────────────┐
   │ frontend  │        │   nginx   │ ──────────► │ backend      │
   │ (Next.js) │──API──►│           │   :9000     │ (php-fpm)    │
   └───────────┘        └───────────┘             └──────┬───────┘
                                                 ┌───────┴────────┐
                                            ┌────▼────┐      ┌────▼────┐
                                            │  mysql  │      │  redis  │
                                            └─────────┘      └─────────┘
```

## Dev vs Production

Compose mặc định là **dev**:
- `frontend` chạy `next dev` (hot-reload), bind-mount `./frontend`.
- `backend` bind-mount `./backend`; entrypoint tự `composer install` nếu thiếu `vendor/`.

Khi lên **production**, tạo `docker-compose.prod.yml` với các thay đổi:
- `frontend`: đổi `image: node...` + `command` thành `build: ./frontend` (Dockerfile multi-stage đã có), truyền `NEXT_PUBLIC_API_URL` qua build arg.
- `backend`: **bỏ** bind-mount `./backend` (code nằm sẵn trong image), đặt `APP_ENV=production`.
- Thêm TLS (Caddy/Traefik hoặc nginx + certbot), không mở cổng 3306/6379 ra ngoài.

Chạy: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build`.

## Lưu ý

- `frontend` cần `next.config.js` có `output: "standalone"` để Dockerfile prod build gọn.
- Không commit file `.env`, `env/backend.env` (đã đưa vào .gitignore).
# anhngu-infra
