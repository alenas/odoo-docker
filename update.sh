#!/bin/bash
podname=odoo
version=14.0.$(date +%m.%d)

### check if install is already there
if [ ! -f set-env-pwd.sh ]; then
     echo 'Seems like there is no existing install, exiting!'
     exit 1
fi

. set-env-pwd.sh

systemctl stop pod-$podname
systemctl disable pod-$podname
systemctl disable container-$podname-app
systemctl disable container-$podname-db
systemctl disable container-$podname-proxy

# in case pod was started not from systemctl
podman pod stop $podname

#echo 'Backing up...'
rsync -a /odoo/ ~/backup/odoo-dir-bkp.$(date +%Y%m%d-%H.%M.%S)
podman rm $podname-app

echo 'Creating APP container: ' $podname-app
podman create --name $podname-app --pod $podname \
    --security-opt seccomp=unconfined \
    --runtime=/usr/lib/cri-o-runc/sbin/runc \
    -e HOST=127.0.0.1 \
    -e USER=odoo \
    -e PASSWORD=$MYSQLPWD \
    -v /$podname/data:/var/lib/odoo \
    -v /$podname/config:/etc/odoo \
    -v /$podname/odoo-addons:/mnt/extra-addons \
        localhost/al3nas/odoo:$version

echo "Creating new services"
podman generate systemd -f -n -t=30 $podname
mv -f *.service /etc/systemd/system/

echo "Enabling services"
systemctl enable pod-$podname
systemctl enable container-$podname-proxy
systemctl enable container-$podname-app
systemctl enable container-$podname-db

systemctl start pod-$podname

echo "Finished ..."
