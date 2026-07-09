# Cấu trúc GitHub & Docker — Dự án Anh ngữ

Quyết định đã chốt: **3 repo tách riêng**, **docker-compose nhiều service**, **MySQL 8**.

## 1. Vì sao 3 repo (không phải 2)?

Bạn chọn tách backend/frontend thành 2 repo, nhưng lại muốn 1 lệnh chạy cả hai.
Hai yêu cầu này cần một chỗ để chứa `docker-compose.yml`. Giải pháp sạch: thêm
repo thứ ba `anhngu-infra` làm "nhạc trưởng", kéo 2 repo kia vào bằng **git submodule**.

```
GitHub (account của bạn)
├── anhngu-backend      # Laravel API — code nghiệp vụ backend
├── anhngu-frontend     # Next.js — code giao diện
└── anhngu-infra        # docker-compose + nginx + env, chứa 2 repo trên dạng submodule
```

Ưu điểm: mỗi repo có version/CI/quyền riêng (đúng ý "tách riêng"), nhưng developer
chỉ cần `git clone --recurse-submodules anhngu-infra` rồi `make up` là chạy full.

> Nếu sau này thấy submodule phiền, có thể chuyển sang cách "clone 2 repo cạnh nhau
> rồi compose trỏ `../anhngu-backend`". Submodule chặt chẽ hơn vì khoá đúng commit.

## 2. Cây thư mục từng repo

### anhngu-backend (Laravel)
```
anhngu-backend/
├── app/                      # Models, Http/Controllers, Services, Enums...
├── database/migrations/
├── database/seeders/
├── routes/api.php
├── bootstrap/app.php
├── docker/
│   └── entrypoint.sh         # chờ DB, composer install, migrate
├── Dockerfile                # php-fpm 8.3-alpine
├── .dockerignore
├── .github/workflows/ci.yml  # Pint + test trên MySQL service
├── .gitignore
├── composer.json
└── .env.example
```

### anhngu-frontend (Next.js)
```
anhngu-frontend/
├── app/                      # App Router (login, (app)/... )
├── lib/                      # api.ts, auth.tsx
├── Dockerfile                # multi-stage, output standalone
├── .dockerignore
├── .github/workflows/ci.yml  # lint + tsc + build
├── .gitignore
├── next.config.js            # nhớ: output: "standalone"
└── package.json
```

### anhngu-infra (điều phối)
```
anhngu-infra/
├── docker-compose.yml        # mysql, redis, backend(php-fpm), nginx, frontend
├── nginx/default.conf        # phục vụ Laravel public + proxy php-fpm
├── env/backend.env.example   # env Laravel (DB_HOST=mysql, REDIS_HOST=redis)
├── .env.example              # biến cho compose (DB_*, NEXT_PUBLIC_API_URL)
├── Makefile                  # make up / fresh / logs / shell-be...
├── gitmodules.example        # mẫu .gitmodules
├── README.md
└── backend/  frontend/       # (submodule, không commit code — chỉ commit con trỏ)
```

## 3. Luồng chạy 1 lệnh

```bash
git clone --recurse-submodules git@github.com:<account>/anhngu-infra.git
cd anhngu-infra
cp .env.example .env
cp env/backend.env.example env/backend.env
make up        # docker compose up -d --build  → chạy 5 container
make fresh     # tạo bảng + seed dữ liệu mẫu
```

Kết quả: Frontend `:3000`, API `:8000`, MySQL `:3306`, Redis `:6379`.

## 4. Nhánh & quy ước Git (gợi ý)

- `main`: code chạy được / đã release. Bảo vệ nhánh, bắt buộc qua PR.
- `develop`: tích hợp tính năng đang làm.
- `feature/<tên>`: mỗi tính năng một nhánh, merge vào `develop` qua PR.
- Commit theo Conventional Commits: `feat:`, `fix:`, `refactor:`, `chore:`...
- CI (GitHub Actions) chạy tự động ở mỗi PR: backend (Pint + test), frontend (lint + build).

## 5. Việc cần làm để khởi tạo thực tế

1. Tạo 3 repo rỗng trên GitHub.
2. Đẩy code Laravel (từ starter đã dựng) lên `anhngu-backend`, thêm `Dockerfile`, `docker/`, CI.
3. Đẩy code Next.js lên `anhngu-frontend`, thêm `Dockerfile`, CI, sửa `next.config.js` thêm `output:"standalone"`.
4. Tạo `anhngu-infra`, copy các file compose/nginx/env, rồi `git submodule add` hai repo kia.
5. Chạy thử `make up` trên máy local.
