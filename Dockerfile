# Combined Jupyter Stacks: Minimal + Data Science + R + Julia + (Scilab/Octave/Haskell kernels)
ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook
FROM $BASE_IMAGE

# Minimal, informational labels only (no maintainer/author fields)
LABEL org.opencontainers.image.title="custom/all-notebooks" \
      org.opencontainers.image.description="Unofficial all-in-one Jupyter image for classroom use"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# ---------- System dependencies (union of Python DS + R + Julia) ----------
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    build-essential gcc gfortran \
    cm-super dvipng \
    ffmpeg \
    fonts-dejavu \
    unixodbc unixodbc-dev r-cran-rodbc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Julia setup ----------
ENV JULIA_DEPOT_PATH=/opt/julia \
    JULIA_PKGDIR=/opt/julia
RUN /opt/setup-scripts/setup_julia.py
RUN rm -rf "/home/${NB_USER}/.cache/"

USER ${NB_UID}
RUN /opt/setup-scripts/setup-julia-packages.bash

# ---------- Python Data Science Stack ----------
RUN mamba install --yes \
    'altair' \
    'beautifulsoup4' \
    'bokeh' \
    'bottleneck' \
    'cloudpickle' \
    'conda-forge::blas=*=openblas' \
    'cython' \
    'dask' \
    'dill' \
    'h5py' \
    'ipympl' \
    'ipywidgets' \
    'jupyterlab-git' \
    'matplotlib-base' \
    'numba' \
    'numexpr' \
    'openpyxl' \
    'pandas' \
    'patsy' \
    'protobuf' \
    'pytables' \
    'scikit-image' \
    'scikit-learn' \
    'scipy' \
    'seaborn' \
    'sqlalchemy' \
    'statsmodels' \
    'sympy' \
    'widgetsnbextension' \
    'xlrd' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Extra python package requested earlier
RUN pip install --no-cache-dir passagemath-standard && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# facets
USER ${NB_UID}
WORKDIR /tmp
RUN git clone https://github.com/PAIR-code/facets && \
    jupyter nbclassic-extension install facets/facets-dist/ --sys-prefix && \
    rm -rf /tmp/facets && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

# ---------- R stack (IRkernel, tidyverse, etc.) ----------
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}
RUN mamba install --yes \
    'r-base' \
    'r-caret' \
    'r-crayon' \
    'r-devtools' \
    'r-e1071' \
    'r-forecast' \
    'r-hexbin' \
    'r-htmltools' \
    'r-htmlwidgets' \
    'r-irkernel' \
    'r-nycflights13' \
    'r-randomforest' \
    'r-rcurl' \
    'r-rmarkdown' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-shiny' \
    'r-tidymodels' \
    'r-tidyverse' \
    'unixodbc' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# ---------- Extra kernels: Scilab, GNU Octave, Haskell (IHaskell) ----------
USER root
# System packages for Scilab, Octave, and IHaskell (ZeroMQ, etc.)
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
      scilab \
      octave \
      gnuplot \
      texinfo \
      curl git pkg-config \
      **gnupg xz-utils netbase make g++** \
      libtinfo-dev libzmq3-dev libgmp-dev libffi-dev zlib1g-dev \
      libcairo2-dev libpango1.0-dev libmagic-dev libblas-dev liblapack-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


USER ${NB_UID}

# --- Octave kernel (Python bridge) ---
# Needs Octave installed already
RUN pip install --no-cache-dir octave_kernel

# --- Scilab kernel ---
# Scilab is already installed via apt
ENV SCILAB_EXECUTABLE=/usr/bin/scilab-cli
RUN pip install --no-cache-dir scilab_kernel && \
    jupyter kernelspec install --sys-prefix "$(
      python -c "import os, scilab_kernel; print(os.path.join(os.path.dirname(scilab_kernel.__file__), 'kernelspec'))"
    )" && \
    jupyter kernelspec list || true

# (optional) sanity check during build
RUN jupyter kernelspec list || true

# --- Haskell Stack (non-interactive install) ---
USER root
# Install stack binary without sudo prompts
RUN curl -L https://get.haskellstack.org/stable/linux-x86_64.tar.gz \
    | tar xz -C /tmp && \
    mv /tmp/stack-*/stack /usr/local/bin/stack && \
    chmod +x /usr/local/bin/stack && \
    rm -rf /tmp/stack-*

# Give Stack a writable root to speed future builds
RUN mkdir -p /opt/stack && chown -R ${NB_UID}:${NB_GID} /opt/stack
USER ${NB_UID}
ENV STACK_ROOT=/opt/stack

# --- IHaskell ---
RUN stack --version && \
    git clone https://github.com/IHaskell/IHaskell /tmp/IHaskell && \
    cd /tmp/IHaskell && \
    pip install --no-cache-dir -r requirements.txt && \
    stack setup && \
    stack install --fast && \
    ihaskell install --stack --prefix=$(jupyter --data-dir) && \
    cd / && rm -rf /tmp/IHaskell


# Optional: list kernels at build time (won't fail the build)
RUN jupyter kernelspec list || true

# Final cache cleanup
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}

WORKDIR "${HOME}"
