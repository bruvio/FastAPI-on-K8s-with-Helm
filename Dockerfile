
FROM python:3.11-slim


RUN apt-get update && apt-get install -y gcc curl wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY prima_sre/ /app/


EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "9000"]
