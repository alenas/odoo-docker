podman pull debian:buster-slim
podman build -t al3nas/odoo:14.0.5.11 \
    --runtime=/usr/lib/cri-o-runc/sbin/runc \
    --squash \
    -f Dockerfile