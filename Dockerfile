
FROM python:3.10-slim-bookworm AS base

FROM base AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        g++ \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download grpc health probe
ENV GRPC_HEALTH_PROBE_VERSION=v0.4.18

RUN wget -qO /bin/grpc_health_probe \
    https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 \
    && chmod +x /bin/grpc_health_probe

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt

RUN pip install --no-cache-dir \
    -r /tmp/requirements.txt

FROM base AS without-grpc-health-probe-bin

ENV PYTHONUNBUFFERED=1
ENV ENABLE_PROFILER=1

WORKDIR /email_server

# Copy installed Python packages
COPY --from=builder /usr/local/lib/python3.10/ /usr/local/lib/python3.10/

# Copy application files
COPY . .

EXPOSE 8080

ENTRYPOINT ["python", "recommendation_server.py"]

FROM without-grpc-health-probe-bin AS final

COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
