ARG UBUNTU_VERSION=24.04
ARG TARGETARCH=amd64

FROM --platform=linux/${TARGETARCH} ubuntu:${UBUNTU_VERSION}

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        # Base development tools
        build-essential \
        cmake \
        ninja-build \
        ccache \
        git \
        wget \
        curl \
        ca-certificates \
        # C++ development
        g++ \
        clang \
        lldb \
        gdb \
        # Python development
        python3 \
        python3-dev \
        python3-pip \
        # Additional utilities
        zip \
        unzip \
        tar \
        pkg-config \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install pixi (cross-platform package manager)
RUN curl -fsSL https://pixi.sh/install.sh | bash \
    && echo 'export PATH="$HOME/.pixi/bin:$PATH"' >> /etc/bash.bashrc

# Set up workspace
WORKDIR /workspace

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# Set default shell
SHELL ["/bin/bash", "-c"]
