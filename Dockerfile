ARG BASE_IMAGE="ghcr.io/yfukai/conda-jax:latest"

FROM ${BASE_IMAGE}
#https://stackoverflow.com/questions/44438637/arg-substitution-in-run-command-not-working-for-dockerfile
ARG BASE_IMAGE

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# maven.repo.local: Make maven store artifacts in our known location
# https.protocols: Force TLS 1.2 to work around a Java bug in the JDK version
ENV MAVEN_OPTS='-Dmaven.repo.local=/opt/scyjava/.m2/repository -Dhttps.protocols=TLSv1.2'
# Configure jgo to create its workspaces in our known location.
ENV JGO_CACHE_DIR='/opt/scyjava/.jgo'
# Our script checks this variable to see whether it's running in the container.
ENV BASICPY_DOCKER_MCMICRO=1

# Installing necessary packages
RUN pip --no-cache-dir install basicpy==1.2.0 bioio 'git+https://github.com/jmuhlich/bioio-bioformats.git@perf-ome-metadata' 'scikit-image>=0.21.0' 'hyperactive<5' && pip uninstall -y aicsimageio bfio

# Pre-fetch bioformats jars to a known location.
RUN --mount=type=bind,source=populate_scyjava_cache.py,target=/tmp/populate_scyjava_cache.py \
    python /tmp/populate_scyjava_cache.py

# Copy script and test run
COPY ./main.py /opt/
# RUN mkdir /data
# COPY ./testdata/exemplar-001-cycle-06.ome.tiff /data/
# RUN /opt/main.py --cpu /data/exemplar-001-cycle-06.ome.tiff /data/
# RUN rm -r /data
