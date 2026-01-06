# Fraud Detection API - Dockerfile
# Uses Python 3.10 as specified in requirements
# Build from project root: docker build -f backend/Dockerfile -t fraud-api .

FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY backend/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy ML model directory
COPY ml/ ./ml/

# Copy backend application code
COPY backend/main.py .

# Expose port 8000
EXPOSE 8000

# Run the FastAPI application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
