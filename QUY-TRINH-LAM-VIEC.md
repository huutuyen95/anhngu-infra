# Quy trình làm việc chung — Dự án Anh ngữ (2 người)

Mục tiêu: rõ ràng, ít lỗi, dễ review. Giữ nhẹ nhàng vì team nhỏ — không cần GitFlow nặng.
Áp dụng cho cả 3 repo: `anhngu-backend`, `anhngu-frontend`, `anhngu-infra`.

---

## 1. Mô hình nhánh (GitHub Flow — đơn giản)

Chỉ 2 loại nhánh:

- `main`: luôn chạy được. **Không ai push thẳng.** Chỉ vào bằng Pull Request đã review.
- `feature/...`: mỗi việc một nhánh, tách ra từ `main`.

Đặt tên nhánh theo việc:
```
feature/dang-nhap          # tính năng mới
fix/loi-cham-diem          # sửa lỗi
refactor/tach-service      # dọn code
```

> Dự án nhỏ 2 người thì **không cần nhánh `develop`**. Có thể thêm sau nếu thấy cần.

---

## 2. Bảo vệ nhánh main (làm 1 lần, mỗi repo)

GitHub → repo → Settings → Branches → Add rule cho `main`:
- ✅ Require a pull request before merging
- ✅ Require approvals: **1** (người kia phải duyệt)
- ✅ (tuỳ chọn) Require status checks: chọn job CI để bắt buộc test pass mới merge được

Kết quả: không ai — kể cả chính mình — lỡ tay push hỏng `main`.

---

## 3. Vòng làm việc hằng ngày (trong 1 repo con)

```bash
git checkout main
git pull                       # lấy code mới nhất

git checkout -b feature/ten-viec
# ... code ...
git add .
git commit -m "feat: thêm màn đăng nhập"
git push -u origin feature/ten-viec
```

Rồi lên GitHub bấm **Compare & pull request** → gán người kia review → sau khi duyệt thì **Squash and merge** vào `main` → xoá nhánh.

Người còn lại sau đó chỉ cần:
```bash
git checkout main && git pull
```

---

## 4. Quy ước commit (Conventional Commits)

`<loại>: <mô tả ngắn, tiếng Việt cũng được>`

| Loại | Khi nào |
|---|---|
| `feat` | thêm tính năng |
| `fix` | sửa lỗi |
| `refactor` | đổi code, không đổi hành vi |
| `chore` | việc lặt vặt (config, deps) |
| `docs` | tài liệu |
| `test` | thêm/sửa test |

Ví dụ: `feat: chấm điểm tự động cho câu trắc nghiệm`

---

## 5. Chia việc để KHÔNG đụng nhau

Vấn đề lớn nhất của 2 người: sửa cùng một file → merge conflict.

- Chia theo **module/màn hình**, không chia theo tầng. Ví dụ: A làm trọn "Đề thi"
  (cả backend controller lẫn frontend page), B làm trọn "Flashcard".
- Dùng **GitHub Issues** cho mỗi việc, gán người phụ trách. Bật tab **Projects**
  (bảng Kanban: Todo / Doing / Done) để nhìn ai đang làm gì.
- PR **nhỏ, merge sớm**. Nhánh sống càng lâu càng dễ conflict.
- Trước khi bắt đầu việc mới, luôn `git pull main` để đứng trên code mới nhất.

---

## 6. Làm việc với SUBMODULE (phần dễ rối nhất)

Repo `anhngu-infra` ghim backend/frontend ở **một commit cụ thể** (detached HEAD —
xem mã hash trong submodule là bình thường, không phải lỗi).

**Quy tắc vàng:**

1. **Sửa code ở repo con, KHÔNG sửa trong thư mục submodule của infra.**
   Tức là clone riêng `anhngu-backend` để code, đừng vào `anhngu-infra/backend` mà gõ.

2. Nếu buộc phải sửa trong submodule, `git checkout main` trước rồi mới code
   (không code ở detached HEAD → tránh mất commit).

3. Sau khi `git pull` repo infra, luôn đồng bộ submodule:
   ```bash
   git submodule update --init --recursive
   ```

4. **Chỉ bump con trỏ submodule một cách CÓ CHỦ ĐÍCH** và báo cho nhau:
   ```bash
   cd anhngu-infra
   git submodule update --remote --merge     # kéo bản mới nhất của submodule
   git add anhngu-backend anhngu-frontend
   git commit -m "chore: bump submodule lên bản mới"
   git push
   ```
   Nếu thấy `git status` ở infra báo submodule "modified" mà bạn không cố ý → **đừng commit**,
   hỏi nhau trước. Đây là nguồn nhầm lẫn số 1 khi làm chung submodule.

---

## 7. Vài luật an toàn

- **Không commit** `.env`, `env/backend.env`, token, mật khẩu (đã có trong .gitignore).
- Không commit `vendor/`, `node_modules/`.
- Mỗi PR nên chạy CI pass (test/lint) trước khi merge.
- Xoá nhánh feature sau khi merge cho gọn.

---

## 8. Tóm tắt siêu ngắn để dán lên tường

```
1. git checkout main && git pull
2. git checkout -b feature/viec-cua-toi
3. code → commit theo "feat:/fix:"
4. push → mở PR → nhờ bạn review
5. squash & merge → xoá nhánh
6. Submodule: code ở repo con, bump con trỏ ở infra khi có chủ đích
```