# SETUP — Dựng môi trường dev (Anh ngữ)

Hướng dẫn cho người mới clone dự án về máy và chạy. Toàn bộ chạy bằng Docker,
**không cần cài PHP / Node / Composer trên máy**.

Kiến trúc: 3 repo — `anhngu-backend` (Laravel 12), `anhngu-frontend` (Next.js),
`anhngu-infra` (docker-compose điều phối). `backend/` và `frontend/` là **git submodule**
của `anhngu-infra`.

---

## 1. Cần cài sẵn

- **Docker Desktop** (đang chạy).
- **Git**.
- Tài khoản GitHub có quyền vào 3 repo. Đăng nhập git qua **Personal Access Token**
  (GitHub không cho dùng mật khẩu): Settings → Developer settings → Tokens (classic),
  tick quyền `repo`. Khi git hỏi password thì dán token.

> **Lưu ý mạng (quan trọng):** quá trình build image tải gói từ kho Alpine
> (`dl-cdn.alpinelinux.org`). Một số mạng (công ty/trường/VPN) chặn kho này, khiến build
> lỗi kiểu `apk ... fetch failed`. Nếu gặp: **bật VPN**, hoặc thêm DNS Google vào
> Docker Desktop → Settings → Docker Engine:
> ```json
> { "dns": ["8.8.8.8", "1.1.1.1"] }
> ```
> rồi Apply & Restart. Test nhanh: `docker run --rm php:8.4-fpm-alpine apk add --no-cache git`
> — chạy được là mạng ổn.

---

## 2. Clone (KÈM submodule)

```bash
git clone --recurse-submodules https://github.com/huutuyen95/anhngu-infra.git
cd anhngu-infra
```

Nếu lỡ clone thiếu submodule (thư mục `backend/`, `frontend/` rỗng):

```bash
git submodule update --init --recursive
```

---

## 3. Tạo file cấu hình (KHÔNG có sẵn trong git)

```bash
cp .env.example .env
cp env/backend.env.example env/backend.env
```

`.env` = biến cho docker-compose. `env/backend.env` = cấu hình Laravel (DB, Redis...).
Hai file này bị `.gitignore` (vì chứa secret) nên mỗi người phải tự tạo từ mẫu `.example`.

> Trong `env/backend.env`, host DB và Redis phải là **tên service** (`mysql`, `redis`),
> KHÔNG phải `127.0.0.1` — vì chúng là các container riêng trong cùng mạng Docker.

---

## 4. Chạy lần đầu

```bash
make up          # = docker compose up -d --build  (build + chạy 5 container)
```

Lần đầu hơi lâu (build image + `composer install` + `npm install`). Theo dõi:

```bash
make logs
```

Sau khi backend chạy, tạo **APP_KEY** (bắt buộc, chỉ làm 1 lần):

```bash
# sinh key rồi ghi vào env/backend.env
KEY=$(docker compose exec -T backend php artisan key:generate --show)
grep -v '^APP_KEY=' env/backend.env > env/backend.env.tmp && mv env/backend.env.tmp env/backend.env
echo "APP_KEY=$KEY" >> env/backend.env

# nạp lại backend để đọc key mới
docker compose up -d --force-recreate backend
```

Tạo bảng + dữ liệu mẫu:

```bash
make fresh       # migrate:fresh --seed
```

---

## 5. Truy cập

| Thành phần | Địa chỉ |
|---|---|
| Frontend (Next.js) | http://localhost:3000 |
| API (Laravel qua nginx) | http://localhost:8000 |
| Health check backend | http://localhost:8000/up (phải ra 200) |
| MySQL | localhost:3306 |
| Redis | localhost:6379 |

Tài khoản seed (sau `make fresh`):
- Giáo viên: `teacher@example.com` / `password`
- Học sinh: `student@example.com` / `password`

---

## 6. Lỗi thường gặp & cách xử lý

Đây là những lỗi đã thực sự gặp khi dựng — đọc trước để đỡ mất thời gian.

**`apk ... fetch failed` / build treo ở bước cài gói**
→ Mạng chặn kho Alpine. Bật VPN hoặc đổi DNS Docker (xem mục 1).

**Trang backend báo "No application encryption key"**
→ Chưa đặt APP_KEY. Làm bước sinh key ở mục 4. Nhớ `--force-recreate backend`
(chỉ `restart` sẽ KHÔNG nạp lại env).

**Container backend "Restarting (255)" / crash loop, hoặc trang trắng**
→ Thường do thiếu `vendor/` (clone mới không có, vì bị gitignore). Cài lại:
```bash
docker compose run --rm --entrypoint composer backend install
docker compose up -d --force-recreate backend
```

**nginx báo "File not found." khi mở localhost:8000**
→ nginx lên trước khi backend sẵn sàng. Chỉ cần:
```bash
docker compose restart nginx
```

**Migration báo "Table ... already exists"**
→ Volume DB còn dữ liệu cũ lẫn lộn. Ở môi trường dev, reset sạch:
```bash
docker compose down -v && make up && make fresh
```
⚠️ `down -v` **xoá sạch database** — chỉ dùng khi chưa có dữ liệu thật.

**Frontend báo `ENOENT ... package.json`**
→ Submodule `frontend` chưa được kéo về: `git submodule update --init --recursive`.

---

## 7. Lệnh hằng ngày (Makefile)

```bash
make up          # chạy toàn bộ
make down        # dừng
make logs        # xem log realtime
make migrate     # chạy migration
make seed        # seed dữ liệu
make fresh       # reset DB + seed
make shell-be    # vào shell container backend
make shell-fe    # vào shell container frontend
```

Chạy artisan trong container:
```bash
docker compose exec backend php artisan <lệnh>
```

---

## 8. Quy trình cập nhật code (làm chung 2 người)

- **Sửa code**: làm trong repo con (`anhngu-backend` / `anhngu-frontend`), theo nhánh
  `feature/...` → PR → merge `main`. Xem `QUY-TRINH-LAM-VIEC.md`.
- **Kéo bản mới nhất của submodule về infra**:
  ```bash
  git submodule update --remote --merge
  git commit -am "chore: cập nhật submodule"
  git push
  ```
- **Không bao giờ** code trực tiếp trong thư mục submodule ở trạng thái detached HEAD
  (thấy mã hash thay vì tên nhánh) — `git checkout main` trước đã.