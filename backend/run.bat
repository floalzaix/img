@echo off
poetry run uvicorn app:app --reload --host 0.0.0.0 --port 5050