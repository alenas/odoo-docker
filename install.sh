#!/bin/bash
podname=odoo
version=14.0e

### check if install is already there
if [ -f set-env-pwd.sh ]; then
    echo 'Seems like there is an existing install, exiting!'
    exit 1
fi

mkdir -p /$podname/data
chmod 666 /$podname/data
mkdir -p /$podname/config
chmod 666 /$podname/config
mkdir -p /$podname/addons
chmod 666 /$podname/addons

mkdir -p /$podname/db

if [ ! -f set-env-pwd.sh ]; then
    echo 'Generating random SQL passwords and saving to set-env.pwd.sh'
    . generate-mysql-pwd.sh
else
    . set-env-pwd.sh
fi

if [ ! -f /$podname/config/odoo.conf ]; then
    echo 'Copying config'
    cp ./14.0/odoo.conf /$podname/config/
    chmod 666 /$podname/config/odoo.conf
fi

echo 'Creating pod: ' $podname
### create pod
podman pod create -n $podname --hostname www.pir.lt \
    -p 80:8069/tcp -p 443:8071/tcp

echo 'Starting pod: ' $podname
podman pod start $podname

echo 'Running DB container: ' $podname-db
### create db container
podman run -d --name $podname-db --pod $podname \
    -v /$podname/db:/var/lib/postgresql/data \
    -e POSTGRES_USER=odoo \
    -e POSTGRES_PASSWORD=$MYSQLPWD \
    -e POSTGRES_DB=postgres \
        docker.io/library/postgres:13-alpine

echo 'Running APP container: ' $podname-app
### create app container - run and then attach to
podman run -d --name $podname-app --pod $podname \
    -e HOST=127.0.0.1 \
    -e USER=odoo \
    -e PASSWORD=$MYSQLPWD \
    -v /$podname/addons:/mnt/extra-addons \
    -v /$podname/data:/var/lib/odoo \
    -v /$podname/config:/etc/odoo \
        localhost/al3nas/odoo:14.0
        
echo 'DONE !'