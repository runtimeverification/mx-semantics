ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-jammy-${K_COMMIT}

RUN    apt-get update                      \
    && apt-get upgrade --yes               \
    && apt-get install --yes               \
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

ARG USER=$USER
ARG GROUP=$GROUP
ARG USER_ID=$USER_ID
ARG GROUP_ID=$USER_ID

RUN groupadd -g $GROUP_ID $USER && useradd -m -u $USER_ID -s /bin/sh -g $USER $USER

USER $USER:$USER
WORKDIR /home/$USER

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly-2023-03-01 --target wasm32-unknown-unknown
ENV PATH=/home/$USER/.cargo/bin:$PATH

ARG PYK_VERSION
RUN python3 -m pip install --upgrade pip
RUN pip3 install --user --upgrade \
                 cytoolz          \
                 numpy            \
                 pysha3           \
                 git+https://github.com/runtimeverification/pyk.git@${PYK_VERSION}

RUN    git clone 'https://github.com/WebAssembly/wabt' --branch 1.0.13 --recurse-submodules wabt \
    && cd wabt                                                                                   \
    && mkdir build                                                                               \
    && cd build                                                                                  \
    && cmake ..                                                                                  \
    && cmake --build .

RUN    wget -O mxpy-up.py https://raw.githubusercontent.com/multiversx/mx-sdk-py-cli/main/mxpy-up.py    \
    && python3 mxpy-up.py --not-interactive

ENV PATH=/home/$USER/multiversx-sdk:/home/$USER/wabt/build:/home/$USER/.local/bin:$PATH

# Use a specific version of rustc installed via rustup
RUN mxpy config set dependencies.rust.resolution host
