FROM python:3.11-slim

WORKDIR /app

COPY . .

# Установка системных зависимостей + обновление pip + установка библиотек
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    fonts-dejavu-core \
    curl \
    && python3 -m ensurepip --upgrade \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir flask psycopg2-binary reportlab \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV FLASK_APP=db.py
ENV FLASK_RUN_HOST=0.0.0.0

EXPOSE 5000

CMD ["flask", "run"]
