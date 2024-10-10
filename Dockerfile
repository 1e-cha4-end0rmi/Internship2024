# Dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY helloworld.py .
CMD ["python", "helloworld.py"]
