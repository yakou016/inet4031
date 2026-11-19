FROM python:3.12-slim

# Apply the zlib fix identified in the initial Trivy report.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       zlib1g=1:1.3.dfsg+really1.3.1-1+deb13u1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]

RUN cd /app
