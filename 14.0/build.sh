if [ ! -f odoo.deb ]; then
     echo 'Missing odoo.deb, exiting !'
     exit 1
fi

podman pull debian:buster-slim
podman build -t al3nas/odoo:14.0.8.02 \
    --runtime=/usr/lib/cri-o-runc/sbin/runc \
    --squash \
    -f Dockerfile
