version=14.0

if [ ! -f $version/odoo.deb ]; then
     echo 'Missing version $version odoo.deb, exiting !'
     return 1
fi

cntversion=$version.$(date +%y%m%d)

# workaround for build context
mkdir -p $version/etc
mount -n --bind etc $version/etc
podman pull debian:buster-slim
podman build -t odoo:$cntversion \
    --security-opt seccomp=unconfined \
    --squash \
    -f $version/Dockerfile
podman tag odoo:$cntversion odoo:latest
umount $version/etc
rmdir $version/etc
