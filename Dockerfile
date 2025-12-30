FROM jupyter/base-notebook:latest
LABEL maintainer="Qiusheng Wu"
LABEL repo="https://github.com/opengeos/segment-geospatial"

USER root
RUN <<EOF
set -e
apt-get -y update
apt-get install -y --no-install-recommends \
    libgl1 \
    sqlite3 \
    libegl1-mesa \
    libgl1-mesa-glx \
    freeglut3-dev \
;
apt-get clean
rm -rf /var/lib/apt/lists/*

mamba install -y -c \
    conda-forge \
    leafmap \
    localtileserver \
    segment-geospatial \
    sam2==0.4.1 \
;
pip install --no-cache-dir --upgrade \
    segment-geospatial \
    jupyter-server-proxy \
    groundingdino-py \
;
mamba update -c conda-forge sqlite -y
# jupyter server extension enable --sys-prefix jupyter_server_proxy
fix-permissions "${CONDA_DIR}"
fix-permissions "/home/${NB_USER}"
EOF

ENV PROJ_LIB='/opt/conda/share/proj'
# ENV JUPYTER_ENABLE_LAB=yes
ARG LOCALTILESERVER_CLIENT_PREFIX='proxy/{port}'
ENV LOCALTILESERVER_CLIENT_PREFIX=$LOCALTILESERVER_CLIENT_PREFIX
