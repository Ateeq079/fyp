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

# Start the application using raw uvicorn to save memory on the Free Tier
# Render automatically maps the exposed port
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]
