ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/minimal-notebook
FROM $BASE_IMAGE

LABEL org.opencontainers.image.title="custom/all-notebooks" \
      org.opencontainers.image.description="Unofficial all-in-one Jupyter image for classroom use"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root
RUN set -eux; \
    curl -L -o /tmp/miniforge.sh \
      "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"; \
    bash /tmp/miniforge.sh -b -p /opt/conda; \
    rm -f /tmp/miniforge.sh; \
    /opt/conda/bin/conda config --set channel_priority strict; \
    /opt/conda/bin/conda create -y -n sage -c conda-forge sagemath python=3.11; \
    /opt/conda/bin/conda clean -afy
ENV PATH="/opt/conda/bin:${PATH}"

# Register the Sage kernel
USER ${NB_UID}
RUN bash -lc "conda run -n sage sage -python -m ipykernel install --user --name 'sage' --display-name 'SageMath'"

# Final cleanup
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}
WORKDIR "${HOME}"
