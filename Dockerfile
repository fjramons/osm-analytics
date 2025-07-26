FROM continuumio/miniconda3:25.3.1-1

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

