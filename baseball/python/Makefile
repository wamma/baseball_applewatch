.PHONY: make

make:
	@rm -rf venv
	@python3 -m venv venv
	@source venv/bin/activate && pip install -r requirements.txt
	@./venv/bin/uvicorn score_server:app --host 0.0.0.0 --port 8000