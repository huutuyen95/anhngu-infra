# Lệnh tắt cho anhngu-infra
.PHONY: up down build logs migrate seed fresh shell-be shell-fe

up:            ## Chạy toàn bộ (build lần đầu)
	docker compose up -d --build

down:          ## Dừng và xoá container
	docker compose down

build:
	docker compose build

logs:          ## Xem log realtime
	docker compose logs -f

migrate:       ## Chạy migration
	docker compose exec backend php artisan migrate

seed:          ## Seed dữ liệu mẫu
	docker compose exec backend php artisan db:seed

fresh:         ## Reset DB + seed
	docker compose exec backend php artisan migrate:fresh --seed

shell-be:      ## Vào shell container backend
	docker compose exec backend sh

shell-fe:      ## Vào shell container frontend
	docker compose exec frontend sh
