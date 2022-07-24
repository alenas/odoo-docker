version=14.0

if [ ! -f $version/odoo.deb ]; then
     echo 'Missing version $version odoo.deb, exiting !'
     exit 1
fi

cntversion=$version.$(date +%y%m%d)

# workaround for build context
mkdir -p $version/etc
mount -n --bind etc $version/etc
#podman pull debian:buster-slim
podman build -t al3nas/odoo:$cntversion \
    --security-opt seccomp=unconfined \
    --squash \
    -f $version/Dockerfile

umount $version/etc
rmdir $version/etc