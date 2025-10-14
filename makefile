run-backend:
	cd backend && poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

run-mobile:
	cd mobile && flutter run
