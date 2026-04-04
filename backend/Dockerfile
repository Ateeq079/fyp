# Use a slim Python image
FROM python:3.12-slim-bookworm

# Copy the uv binary from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Install dependencies separately for caching
# (This includes the lockfile and pyproject.toml)
COPY pyproject.toml uv.lock ./

# Install project dependencies into a system-wide environment
# (Recommended for Docker containers)
RUN uv sync --frozen --no-install-project

# Copy the rest of the application
COPY . .

# Ensure the upload directory exists in the container
RUN mkdir -p /app/uploads

# Expose the default Render port
EXPOSE 10000

# Start the application using gunicorn with uvicorn workers for production
# Render automatically provides the PORT environment variable
CMD ["uv", "run", "gunicorn", "app.main:app", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:10000"]
