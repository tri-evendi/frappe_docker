# syntax=docker/dockerfile:1.3

ARG PYTHON_VERSION
FROM python:${PYTHON_VERSION}-slim-bullseye as base

FROM frappe/bench:latest as assets_builder

ARG FRAPPE_VERSION
ARG FRAPPE_REPO=https://github.com/frappe/frappe
ARG PYTHON_VERSION
ARG NODE_VERSION
ENV NVM_DIR=/home/frappe/.nvm
ENV PATH ${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/:${PATH}
RUN PYENV_VERSION=${PYTHON_VERSION} bench init --version=${FRAPPE_VERSION} --frappe-path=${FRAPPE_REPO} --skip-redis-config-generation --verbose --skip-assets /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

FROM base as build_deps

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    # Install git here because it is not required in production
    git \
    # gcc and g++ are required for building different packages across different versions
    # of Frappe and ERPNext and also on different platforms (for example, linux/arm64).
    # It is safe to install build deps even if they are not required
    # because they won't be included in final images.
    gcc \
    g++ \
    # golang compiler is required for installing reflex
    golang \
    # nano is required for debugging
    nano \
    # Make is required to build wheels of ERPNext deps in develop branch for linux/arm64
    make \
    && rm -rf /var/lib/apt/lists/*

FROM assets_builder as frappe_assets

RUN bench setup requirements \
    && if [ -z "${FRAPPE_VERSION##*v14*}" ] || [ "$FRAPPE_VERSION" = "develop" ]; then \
        export BUILD_OPTS="--production";\
    fi \
    && FRAPPE_ENV=production bench build --verbose --hard-link ${BUILD_OPTS}


FROM assets_builder as erpnext_assets

ARG ERPNEXT_VERSION
ARG ERPNEXT_REPO=https://github.com/frappe/erpnext
RUN bench get-app --branch=${ERPNEXT_VERSION} --skip-assets --resolve-deps erpnext ${ERPNEXT_REPO}\
    && if [ -z "${ERPNEXT_VERSION##*v14*}" ] || [ "$ERPNEXT_VERSION" = "develop" ]; then \
        export BUILD_OPTS="--production"; \
    fi \
    && FRAPPE_ENV=production bench build --verbose --hard-link ${BUILD_OPTS}

FROM erpnext_assets as press_assets

ARG PRESS_VERSION
ARG PRESS_REPO=https://github.com/tri-evendi/press
RUN bench get-app --branch=${PRESS_VERSION} --skip-assets --resolve-deps press ${PRESS_REPO}\
    && if [ "$PRESS_VERSION" = "develop" ]; then \
        export BUILD_OPTS="--production"; \
    fi \
    && FRAPPE_ENV=production bench build --verbose --hard-link ${BUILD_OPTS}


FROM alpine/git as bench

# Error pages
ARG BENCH_REPO=https://github.com/frappe/bench
RUN git clone --depth 1 ${BENCH_REPO} /tmp/bench \
    && mkdir /out \
    && mv /tmp/bench/bench/config/templates/502.html /out \
    && touch /out/.build

FROM nginxinc/nginx-unprivileged:1.23.2-alpine as frappe

# https://github.com/nginxinc/docker-nginx-unprivileged/blob/main/stable/alpine/20-envsubst-on-templates.sh
COPY nginx-template.conf /etc/nginx/templates/default.conf.template
# https://github.com/nginxinc/docker-nginx-unprivileged/blob/main/stable/alpine/docker-entrypoint.sh
COPY entrypoint.sh /docker-entrypoint.d/frappe-entrypoint.sh

COPY --from=bench /out /usr/share/nginx/html/
COPY --from=frappe_assets /home/frappe/frappe-bench/sites/assets /usr/share/nginx/html/assets

USER 1000


FROM frappe as erpnext

COPY --from=erpnext_assets /home/frappe/frappe-bench/sites/assets /usr/share/nginx/html/assets

FROM frappe as press

COPY --from=press_assets /home/frappe/frappe-bench/sites/assets /usr/share/nginx/html/assets
