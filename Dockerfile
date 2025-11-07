# Combined Jupyter Stacks: Minimal + R 
ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook
FROM $BASE_IMAGE

LABEL org.opencontainers.image.title="custom/all-notebooks" \
      org.opencontainers.image.description="Unofficial all-in-one Jupyter image for classroom use"

# Make bash strict and pipefail-aware in all RUNs
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# We’ll use the conda that already exists in this base image
USER root
ENV CONDA_DIR=/opt/conda
ENV PATH="${CONDA_DIR}/bin:${PATH}"



RUN set -eux; \
    # Keep solves deterministic-ish and fast
    "${CONDA_DIR}/bin/conda" config --set channel_priority strict; \
    "${CONDA_DIR}/bin/conda" install -y -n base -c conda-forge mamba; \
    # Create Sage env pinned to Python 3.11
    # (use conda-forge; package name is "sage")
    "${CONDA_DIR}/bin/mamba" create -y -n sage -c conda-forge "sage>=10.4" python=3.11; \
    # Clean caches and ensure the notebook user can modify envs later
    "${CONDA_DIR}/bin/conda" clean -afy; \
    chown -R ${NB_UID}:${NB_GID} "${CONDA_DIR}"


# From SageMath installation documentation
# Register the Sage kernel (run as the notebook user)
USER ${NB_UID}
RUN bash -lc 'eval "$(/opt/conda/bin/conda shell.bash hook)" \
  && conda activate sage \
  && KDIR="$(sage -sh -c "ls -d \$SAGE_VENV/share/jupyter/kernels/sagemath")" \
  && jupyter kernelspec install --user "$KDIR" --name sagemath-dev'
  

# sanity check during build
RUN jupyter kernelspec list || true

# Extra python packages for Python Kernel
RUN pip --no-cache-dir install \
      numpy \
      sympy \
      scipy \
      tqdm

# ---------- R stack (IRkernel, tidyverse, etc.) ----------
USER root
RUN set -eux; \
    mamba install --yes \
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

# Register IRkernel for the notebook user
USER ${NB_UID}
RUN R -q -e "IRkernel::installspec(user = TRUE)"


# ---------- GNU Octave ----------
USER root
# System packages for Octave
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
      octave \
      gnuplot \
      texinfo \
      curl git pkg-config \
      gnupg xz-utils netbase make g++ \
      libtinfo-dev libzmq3-dev libgmp-dev libffi-dev zlib1g-dev \
      libcairo2-dev libpango1.0-dev libmagic-dev libblas-dev liblapack-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


USER ${NB_UID}

# --- Octave kernel (Python bridge) ---
# Needs Octave installed already
RUN pip install --no-cache-dir octave_kernel


# sanity check during build
RUN jupyter kernelspec list || true


# Final tidy
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}

WORKDIR "${HOME}"
