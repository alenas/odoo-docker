podman rmi al3nas/odoo:14.0
podman build -t al3nas/odoo:14.0 \
    --runtime=/usr/lib/cri-o-runc/sbin/runc \
    --squash \
    -f Dockerfile