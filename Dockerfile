# FRAS frontend
FROM node:20-alpine AS fras-frontend-builder
WORKDIR /app/fras-frontend
COPY facial-recognition-attendance-system/frontend/package*.json ./
RUN npm ci
COPY facial-recognition-attendance-system/frontend/ .
RUN npm run build


# Final multi-service image
FROM python:3.11-slim
WORKDIR /app

# Install NGINX, Supervisor, and dependencies
RUN apt-get update && apt-get install -y nginx supervisor curl libxcb1 libxext6 libsm6 libxrender1 ffmpeg libgl1 && rm -rf /var/lib/apt/lists/*

# Install Python requirements
COPY facial-recognition-attendance-system/backend/requirements.txt .
RUN pip install -r requirements.txt

# Blog
COPY blog/ ./blog

# Portfolio
COPY portfolio/ ./portfolio

# Copy built applications
COPY facial-recognition-attendance-system/backend/ /opt/fras-backend
COPY --from=fras-frontend-builder /app/fras-frontend/dist /var/www/fras

# Copy NGINX and Supervisor configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports
EXPOSE 80
EXPOSE 7860

# Start Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
