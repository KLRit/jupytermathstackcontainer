# Combined Jupyter Stacks: Minimal + Data Science + R + Julia
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
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

RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
      bash Miniforge3-$(uname)-$(uname -m).sh && \
      conda create -n sage sage python=3.11


# Final cache cleanup (Rosetta note as above)
USER root
RUN rm -rf "/home/${NB_USER}/.cache/"
USER ${NB_UID}

WORKDIR "${HOME}"
