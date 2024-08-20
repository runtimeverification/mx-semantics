ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-jammy-${K_COMMIT}

RUN    apt-get update                      \
    && apt-get upgrade --yes               \
    && apt-get install --yes               \
                       autoconf            \
                       libtool             \
                       cmake               \
                       curl                \
                       wget                \
                       libcrypto++-dev     \
                       libsecp256k1-dev    \
                       libssl-dev          \
                       pandoc              \
                       python3             \
                       python3-pip         \
                       python3-venv        \
                       wabt

RUN    curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr python3 - \
    && poetry --version

ARG USER=github-user
ARG GROUP=$USER
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID

RUN groupadd -g $GROUP_ID $GROUP && useradd -m -u $USER_ID -s /bin/sh -g $GROUP $USER

USER $USER:$GROUP
WORKDIR /home/$USER

RUN python3 -m pip install --upgrade pip

RUN wget -O rustup.sh https://sh.rustup.rs && \
    chmod +x rustup.sh && \
    ./rustup.sh --verbose --target wasm32-unknown-unknown -y

ENV PATH="/home/${USER}/.cargo/bin:${PATH}"

RUN cargo install multiversx-sc-meta --version ~0.50 --locked
