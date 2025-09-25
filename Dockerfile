ARG BASE_IMAGE="ghcr.io/yfukai/conda-jax:latest"

FROM ${BASE_IMAGE}
#https://stackoverflow.com/questions/44438637/arg-substitution-in-run-command-not-working-for-dockerfile
ARG BASE_IMAGE

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Installing necessary packages

# Installing basicpy and other pip packages
RUN pip --no-cache-dir install basicpy==1.2.0 bioformats_jar 'scikit-image>=0.21.0' 'hyperactive<5'

# Pre-fetch bioformats jars to a world-readable location.
# Force TLS 1.2 to work around a Java bug in the JDK version in this container.
RUN env JAVA_TOOL_OPTIONS='-Dhttps.protocols=TLSv1.2' \
    python -c 'import bioformats_jar; bioformats_jar.get_loci()' \
    && mv /root/.jgo /root/.m2 /tmp \
    && chmod -R a+rwX /tmp/.jgo /tmp/.m2
ENV HOME=/tmp

# Copy script and test run
COPY ./main.py /opt/
# RUN mkdir /data
# COPY ./testdata/exemplar-001-cycle-06.ome.tiff /data/
# RUN /opt/main.py --cpu /data/exemplar-001-cycle-06.ome.tiff /data/
# RUN rm -r /data
