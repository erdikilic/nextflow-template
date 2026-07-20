# syntax=docker/dockerfile:1
#
# Example custom container. Build and push, then reference by BARE name in the
# module (the registry is set once in nextflow.config):
#   docker build -t quay.io/erdikilic/example:0.1.0 containers/example
#   docker push  quay.io/erdikilic/example:0.1.0
#   # in modules/local/<tool>/main.nf:  container 'erdikilic/example:0.1.0'
FROM mambaorg/micromamba:2.8.1

LABEL org.opencontainers.image.source="https://github.com/erdikilic/nextflow-template" \
      org.opencontainers.image.licenses="Apache-2.0"

USER root
RUN apt-get update && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

# Install tools via micromamba, e.g.:
# COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml
# RUN micromamba install -y -n base -f /tmp/environment.yml \
#     && micromamba clean --all --yes
