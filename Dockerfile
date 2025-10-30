ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook
FROM $BASE_IMAGE

LABEL org.opencontainers.image.title="custom/all-notebooks" \
      org.opencontainers.image.description="Unofficial all-in-one Jupyter image for classroom use"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Sagemath into its own env and register a kernel
USER ${NB_UID}
ENV MAMBA_DOCKERFILE_ACTIVATE=1

RUN micromamba create -y -n sage -c conda-forge sagemath python=3.11 && \
    micromamba clean -a -y && \
    micromamba run -n sage sage -python -m ipykernel install --user \
      --name "sage" --display-name "SageMath"

# Tidy caches
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}

WORKDIR "${HOME}"
