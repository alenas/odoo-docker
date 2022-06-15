#!/bin/bash
podname=odoo
version=14.1.06.15

### check if install is already there
if [ ! -f set-env-pwd.sh ]; then
     echo 'Seems like there is no existing install, exiting!'
     exit 1
fi

systemctl stop pod-$podname
systemctl disable pod-$podname
systemctl disable container-$podname-app
systemctl disable container-$podname-db
systemctl disable container-$podname-proxy

### clean the log
rm /odoo/data/odoo.log

. set-env-pwd.sh

echo 'Creating APP container: ' $podname-app
podman rm $podname-app
podman create --name $podname-app --pod $podname \
    --cgroups=disabled \
    -e HOST=127.0.0.1 \
    -e USER=odoo \
    -e PASSWORD=$MYSQLPWD \
    -v /$podname/data:/var/lib/odoo \
    -v /$podname/config:/etc/odoo \
    -v /$podname/odoo-addons:/mnt/extra-addons \
    -v /$podname/vialaurea:/mnt/vialaurea \
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
