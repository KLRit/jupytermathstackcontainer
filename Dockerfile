# Combined Jupyter Stacks: Minimal + Data Science + R + Julia
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

# Register the Sage kernel (run as the notebook user)
USER ${NB_UID}
RUN conda run -n sage sage -python -m ipykernel install --user \
      --name "sage" --display-name "SageMath (Py 3.11)"

# Final tidy
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}

WORKDIR "${HOME}"
