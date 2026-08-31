FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/backend

WORKDIR /backend

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libmariadb-dev \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt /backend/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files and migrations
COPY alembic.ini /backend/
COPY alembic /backend/alembic
COPY entrypoint.sh /backend/
RUN chmod +x /backend/entrypoint.sh
COPY app /backend/app

# Expose port
EXPOSE 8000

# Set entrypoint and default command
ENTRYPOINT ["/backend/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
