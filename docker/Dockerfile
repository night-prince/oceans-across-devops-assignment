FROM python:3.12-slim

ARG APP_SERVICE=backend

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_PORT=8080 \
    APP_SERVICE=${APP_SERVICE} \
    APP_ENVIRONMENT=dev

WORKDIR /app

RUN useradd --system --uid 10001 appuser

RUN python - <<'PY'
from pathlib import Path
Path("/app/server.py").write_text(
"""from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        payload = {
            "status": "ok",
            "service": os.getenv("APP_SERVICE", "unknown"),
            "environment": os.getenv("APP_ENVIRONMENT", "dev")
        }

        if self.path in ("/", "/health"):
            body = json.dumps(payload).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        return

HTTPServer(("0.0.0.0", int(os.getenv("APP_PORT", "8080"))), Handler).serve_forever()
"""
)
PY

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

CMD ["python", "/app/server.py"]