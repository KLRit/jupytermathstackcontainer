# Combined Jupyter Stacks: Minimal + Data Science + R + Julia
ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook
FROM $BASE_IMAGE

LABEL org.opencontainers.image.title="custom/all-notebooks" \
      org.opencontainers.image.description="Unofficial all-in-one Jupyter image for classroom use"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Use the existing /opt/conda if present; otherwise install Miniforge there.
USER root
ENV CONDA_DIR=/opt/conda
ENV PATH="${CONDA_DIR}/bin:${PATH}"

RUN set -eux; \
    if [ ! -x "${CONDA_DIR}/bin/conda" ]; then \
      curl -L -o /tmp/miniforge.sh \
        "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"; \
      bash /tmp/miniforge.sh -b -p "${CONDA_DIR}"; \
      rm -f /tmp/miniforge.sh; \
    fi; \
    "${CONDA_DIR}/bin/conda" config --set channel_priority strict; \
    # (optional) ensure mamba exists for faster solves
    "${CONDA_DIR}/bin/conda" install -y -n base -c conda-forge mamba; \
    # create Sage env (note: package name is sagemath)
    "${CONDA_DIR}/bin/mamba" create -y -n sage -c conda-forge sagemath python=3.11; \
    "${CONDA_DIR}/bin/conda" clean -afy; \
    # let the notebook user own conda so kernels/extensions can be added later
    chown -R ${NB_UID}:${NB_GID} "${CONDA_DIR}"

# Register the kernel as the notebook user
USER ${NB_UID}
RUN conda run -n sage sage -python -m ipykernel install --user \
      --name "sage" --display-name "SageMath"

# Tidy caches
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}

WORKDIR "${HOME}"
