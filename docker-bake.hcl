# Docker Buildx Bake build definition file
# Reference: https://github.com/docker/buildx/blob/master/docs/reference/buildx_bake.md

variable "REGISTRY_USER" {
    default = "tandigital"
}

variable "FRAPPE_VERSION" {
    default = "develop"
}

variable "ERPNEXT_VERSION" {
    default = "develop"
}

variable "PRESS_VERSION" {
    default = "develop"
}

variable "FRAPPE_REPO" {
    default = "https://github.com/frappe/frappe"
}

variable "ERPNEXT_REPO" {
    default = "https://github.com/frappe/erpnext"
}

variable "PRESS_REPO" {
    default = "https://github.com/tri-evendi/press"
}

variable "BENCH_REPO" {
    default = "https://github.com/frappe/bench"
}

# Bench image

target "bench" {
    args = {
        GIT_REPO = "${BENCH_REPO}"
    }
    context = "images/bench"
    target = "bench"
    tags = ["frappe/bench:latest"]
}

target "bench-test" {
    inherits = ["bench"]
    target = "bench-test"
}

# Main images
# Base for all other targets

group "frappe" {
    targets = ["frappe-worker", "frappe-nginx", "frappe-socketio"]
}

group "erpnext" {
    targets = ["erpnext-worker", "erpnext-nginx"]
}

group "press" {
    targets = ["press-worker", "press-nginx"]
}

group "default" {
    targets = ["frappe", "erpnext", "press"]
}

function "tag" {
    params = [repo, version]
    result = [
      # If `version` param is develop (development build) then use tag `latest`
      "${version}" == "develop" ? "${REGISTRY_USER}/${repo}:latest" : "${REGISTRY_USER}/${repo}:${version}",
      # Make short tag for major version if possible. For example, from v13.16.0 make v13.
      can(regex("(v[0-9]+)[.]", "${version}")) ? "${REGISTRY_USER}/${repo}:${regex("(v[0-9]+)[.]", "${version}")[0]}" : "",
    ]
}

target "default-args" {
    args = {
        FRAPPE_REPO = "${FRAPPE_REPO}"
        ERPNEXT_REPO = "${ERPNEXT_REPO}"
        PRESS_REPO = "${PRESS_REPO}"
        BENCH_REPO = "${BENCH_REPO}"
        FRAPPE_VERSION = "${FRAPPE_VERSION}"
        ERPNEXT_VERSION = "${ERPNEXT_VERSION}"
        PRESS_VERSION = "${PRESS_VERSION}"
        PYTHON_VERSION = can(regex("v13", "${ERPNEXT_VERSION}")) ? "3.9.9" : "3.10.5"
        NODE_VERSION = can(regex("v13", "${FRAPPE_VERSION}")) ? "14.19.3" : "16.18.0"
    }
}

target "frappe-worker" {
    inherits = ["default-args"]
    context = "images/worker"
    target = "frappe"
    tags = tag("frappe-worker", "${FRAPPE_VERSION}")
    platforms = ["linux/amd64"]
}

target "erpnext-worker" {
    inherits = ["default-args"]
    context = "images/worker"
    target = "erpnext"
    tags =  tag("erpnext-worker", "${ERPNEXT_VERSION}")
    platforms = ["linux/amd64"]
}

target "press-worker" {
    inherits = ["default-args"]
    context = "images/worker"
    target = "press"
    tags =  tag("press-worker", "${PRESS_VERSION}")
    platforms = ["linux/amd64"]
}

target "frappe-nginx" {
    inherits = ["default-args"]
    context = "images/nginx"
    target = "frappe"
    tags =  tag("frappe-nginx", "${FRAPPE_VERSION}")
    platforms = ["linux/amd64"]
}

target "erpnext-nginx" {
    inherits = ["default-args"]
    context = "images/nginx"
    target = "erpnext"
    tags =  tag("erpnext-nginx", "${ERPNEXT_VERSION}")
    platforms = ["linux/amd64"]
}

target "press-nginx" {
    inherits = ["default-args"]
    context = "images/nginx"
    target = "press"
    tags =  tag("press-nginx", "${PRESS_VERSION}")
    platforms = ["linux/amd64"]
}

target "frappe-socketio" {
    inherits = ["default-args"]
    context = "images/socketio"
    tags =  tag("frappe-socketio", "${FRAPPE_VERSION}")
}
