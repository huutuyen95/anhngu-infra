# CLAUDE.md — anhngu-infra

Repo **điều phối**: chạy toàn bộ hệ thống bằng Docker. Code thật nằm ở 2 submodule.

## Cấu trúc 3 repo

```
anhngu-infra (repo này)      ← docker-compose, nginx, env, tài liệu
├── backend/   (submodule → anhngu-backend)   Laravel 12 API
└── frontend/  (submodule → anhngu-frontend)  Next.js
```

- `backend/` và `frontend/` là **git submodule**. Sửa code thì làm trong đó và commit ở
  **repo con**, sau đó bump con trỏ submodule ở repo này (`git add backend && git commit`).
- Mỗi submodule có `CLAUDE.md` riêng — đọc thêm khi làm việc trong đó.

## Chạy hệ thống

```bash
make up          # docker compose up -d --build  (mysql, redis, backend, nginx, frontend)
make fresh       # migrate:fresh --seed
make logs
make down
```

- Frontend: http://localhost:3000 · API: http://localhost:8000 · Health: /up
- Chi tiết cài đặt + lỗi thường gặp: **`SETUP.md`**.

## ⚠️ Chạy lệnh trong container (không có PHP/Node/Composer trên máy)

```bash
docker compose exec backend php artisan <lệnh>      # Laravel
docker compose exec backend composer <lệnh>
docker compose exec frontend npm <lệnh>             # Next.js
```

## Cấu hình

- `.env` (biến cho docker-compose) và `env/backend.env` (env Laravel) — **KHÔNG có trong git**,
  tự tạo từ `*.example`. Chứa secret (APP_KEY, DB...), KHÔNG commit.
- Host DB/Redis trong `env/backend.env` là **tên service** (`mysql`, `redis`), không phải `127.0.0.1`.

## Vài lỗi hay gặp (chi tiết ở SETUP.md)

- Build lỗi `apk fetch failed` → mạng chặn kho Alpine, bật VPN / đổi DNS Docker.
- Mở `localhost:8000` báo "File not found" → `docker compose restart nginx`.
- Backend crash loop → thiếu `vendor/`: `docker compose run --rm --entrypoint composer backend install`.

## Tài liệu (đọc khi cần)

- `SETUP.md` — dựng môi trường + lỗi thường gặp.
- `QUY-TRINH-LAM-VIEC.md` — quy ước git / nhánh / submodule cho 2 người.
- `KE-HOACH-SPRINT.md` — roadmap 4 sprint / 1 tháng.
- `PHAN-TICH-DE-THI.md` — thiết kế engine đề thi (4 loại câu).

## Quy ước git

- Nhánh: `main` (bảo vệ, chỉ vào qua PR) + `feature/...`. Conventional Commits.
- KHÔNG commit `.env`, `env/backend.env`.
- Sửa submodule: `git checkout main` trong submodule trước (tránh detached HEAD), rồi mới code.