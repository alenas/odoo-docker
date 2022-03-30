#!/bin/bash
podname=odoo
version=15.0.$(date +%m.%d)

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
rsync -a --exclude=/odoo/data/backups/ /odoo/ ~/backup/odoo-dir-bkp.$(date +%Y%m%d-%H.%M.%S)

# echo 'Updating Traefik: ' $podname-proxy
# podman rm $podname-proxy
# podman create --name $podname-proxy --pod $podname \
#     --cgroups=disabled \
#     -v /$podname/proxy:/etc/traefik \
#         docker.io/library/traefik:2.6

# echo 'Updating DB container: ' $podname-db
# podman rm $podname-db
# podman create --name $podname-db --pod $podname \
#     --cgroups=disabled \
#     -v /$podname/db:/var/lib/postgresql/data \
#     -e POSTGRES_USER=odoo \
#     -e POSTGRES_PASSWORD=$MYSQLPWD \
#     -e POSTGRES_DB=postgres \
#         docker.io/library/postgres:14-alpine


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
