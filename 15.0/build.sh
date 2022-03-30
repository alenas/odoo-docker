if [ ! -f odoo.deb ]; then
    echo 'Missing odoo.deb, exiting !'
    exit 1
fi

version=15.0.$(date +%m.%d)

podman pull debian:bullseye-slim
podman build -t al3nas/odoo:$version \
    --squash \
    -f Dockerfile
