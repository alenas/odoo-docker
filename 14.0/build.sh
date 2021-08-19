if [ ! -f odoo.deb ]; then
     echo 'Missing odoo.deb, exiting !'
     exit 1
fi

version=14.0.$(date +%m.%d)

podman pull debian:buster-slim
podman build -t al3nas/odoo:$version \
    --runtime=/usr/lib/cri-o-runc/sbin/runc \
    --squash \
    -f Dockerfile
