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
                       libprocps-dev       \
                       libsecp256k1-dev    \
                       libssl-dev          \
                       pandoc              \
                       python3             \
                       python3-pip         \
                       python3-venv

RUN    curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr python3 - \
    && poetry --version

ARG USER=github-user
ARG GROUP=$USER
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID

RUN groupadd -g $GROUP_ID $GROUP && useradd -m -u $USER_ID -s /bin/sh -g $GROUP $USER

USER $USER:$GROUP
WORKDIR /home/$USER

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly-2023-03-01 --target wasm32-unknown-unknown
ENV PATH=/home/$USER/.cargo/bin:$PATH

RUN python3 -m pip install --upgrade pip

RUN    git clone 'https://github.com/WebAssembly/wabt' --branch 1.0.13 --recurse-submodules wabt \
    && cd wabt                                                                                   \
    && mkdir build                                                                               \
    && cd build                                                                                  \
    && cmake ..                                                                                  \
    && cmake --build .

RUN    wget -O mxpy-up.py https://raw.githubusercontent.com/multiversx/mx-sdk-py-cli/main/mxpy-up.py    \
    && python3 mxpy-up.py --not-interactive --exact-version 7.3.0

ENV PATH=/home/$USER/multiversx-sdk:/home/$USER/wabt/build:/home/$USER/.local/bin:$PATH

# Use a specific version of rustc installed via rustup
RUN mxpy config set dependencies.rust.resolution host
