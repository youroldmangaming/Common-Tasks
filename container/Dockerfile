FROM debian:latest

# Set environment to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update apt cache and install base packages in one step
# Using a loop for update to handle transient network issues
RUN for i in 1 2 3; do apt-get update && break || sleep 10; done && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install network utilities and nano, ensuring a fresh update
RUN for i in 1 2 3; do apt-get update && break || sleep 10; done && \
    apt-get install -y --no-install-recommends \
    iputils-ping \
    net-tools \
    nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python and pip, ensuring a fresh update
RUN for i in 1 2 3; do apt-get update && break || sleep 10; done && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm, ensuring a fresh update
RUN for i in 1 2 3; do apt-get update && break || sleep 10; done && \
    apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the default command to run when the container starts
CMD ["/bin/bash"]
