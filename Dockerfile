FROM continuumio/miniconda3:25.3.1-1

# OpenContainers labels
LABEL org.opencontainers.image.authors="Francisco-Javier Ramón Salguero"
LABEL org.opencontainers.image.source=https://github.com/fjramons/osm-analytics
LABEL org.opencontainers.image.title="OSM Analytics"
LABEL org.opencontainers.image.description="OSM Analytics is a set of tools and scripts to analyze statistics from development tools of ETSI OSM, but which are suitable for other projects with the same tooling"
LABEL org.opencontainers.image.licenses=GPL-3.0-or-later

# To allow scripts to identify if running from a container
ENV IN_CONTAINER=true

# Options
ARG ENVFILE=environment-docker-frozen.yml
ARG DEVELOPMENT=

COPY ${ENVFILE} environment.yml

RUN conda env update -n base --file environment.yml && \
    apt-get update && apt-get install -y --no-install-recommends lftp && \
    # Cleanup
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    opt/conda/bin/conda clean -afy && \
    rm -rf /var/lib/apt/lists/*

# If it is intended for development, install also Jupyter Notebook server
RUN if [ "${DEVELOPMENT}" = "true" ]; then \
        conda install jupyter -y --quiet && \
        # Cleanup
        find /opt/conda/ -follow -type f -name '*.a' -delete && \
        find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
        opt/conda/bin/conda clean -afy ; \
    fi

WORKDIR /osm-analytics

# Copy `Bugzilla/` `Installations/` and `Jenkins/` folders
ADD . ./

