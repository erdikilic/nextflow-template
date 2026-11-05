# syntax=docker/dockerfile:1
#
# Example custom container. Build and push, then reference it by its full name
# in the module:
#   docker build -t quay.io/erdikilic/example:0.1.0 containers/example
#   docker push  quay.io/erdikilic/example:0.1.0
#   # in modules/local/<tool>/main.nf:  container 'quay.io/erdikilic/example:0.1.0'
FROM mambaorg/micromamba:2.10.0

LABEL org.opencontainers.image.source="https://github.com/erdikilic/nextflow-template" \
      org.opencontainers.image.licenses="Apache-2.0"

USER 0
RUN apt-get update && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
# 57439 is MAMBA_USER_ID / MAMBA_USER_GID (mambauser) in the micromamba base image.
USER 57439:57439

# Install tools via micromamba, e.g.:
# COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml
# RUN micromamba install -y -n base -f /tmp/environment.yml \
#     && micromamba clean --all --yes
