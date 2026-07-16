# Stage 1: Build the portfolio (static files)
FROM node:18-alpine AS portfolio-builder
WORKDIR /app/portfolio
COPY vinaykatikireddy/ ./
RUN npm install -g serve

# Stage 2: Build the FRAS backend
FROM python:3.11-slim AS fras-builder
WORKDIR /app/fras

RUN apt-get update && apt-get install -y \
    build-essential \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

COPY facial-recognition-attendance-system/backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY facial-recognition-attendance-system/backend/ .

# Stage 3: Final multi-service image
FROM python:3.11-slim

# Install NGINX, Supervisor, and dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    curl \
    libxcb1 \
    libxext6 \
    libsm6 \
    libxrender1 \
    ffmpeg \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for `serve`
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs

# Copy requirements.txt from fras-builder and install all dependencies
COPY --from=fras-builder /app/fras/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy built applications
COPY --from=portfolio-builder /app/portfolio /var/www/portfolio
COPY --from=fras-builder /app/fras /var/www/fras

# Copy NGINX and Supervisor configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports
EXPOSE 80
EXPOSE 7860

# Start Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]