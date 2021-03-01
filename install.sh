#!/bin/bash
podname=odoo

### check if install is already there
# if [ -f set-env-pwd.sh ]; then
#     echo 'Seems like there is an existing install, exiting!'
#     exit 1
# fi

mkdir -p /$podname/data
chmod 777 /$podname/data
mkdir -p /$podname/config
chmod 777 /$podname/config
mkdir -p /$podname/proxy
chmod 666 /$podname/proxy

mkdir -p /$podname/db

if [ ! -f set-env-pwd.sh ]; then
    echo 'Generating random SQL passwords and saving to set-env.pwd.sh'
    . generate-mysql-pwd.sh
else
    . set-env-pwd.sh
fi

if [ ! -f /$podname/config/odoo.conf ]; then
    echo 'Copying odoo config...'
    cp ./14.0/odoo.conf /$podname/config/
    chmod 666 /$podname/config/odoo.conf
fi

if [ ! -f /$podname/proxy/traefik.yaml ]; then
    echo 'Copying proxy config...'
    cp ./etc/traefik/* /$podname/proxy/
    chmod -R 666 /$podname/proxy
fi


echo 'Creating pod: ' $podname
### create pod
podman pod create -n $podname --hostname www.pir.lt \
    -p 80:80/tcp -p 443:443/tcp -p 8080:8080/tcp

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

echo 'Running traefik reverse-proxy...'
podman run -d --name reverse-proxy --pod $podname \
    -v /$podname/proxy:/etc/traefik \
        docker.io/library/traefik:2.4

echo 'Running APP container: ' $podname-app
### create app container - run and then attach to
podman run -d --name $podname-app --pod $podname \
    -e HOST=127.0.0.1 \
    -e USER=odoo \
    -e PASSWORD=$MYSQLPWD \
    -v /$podname/data:/var/lib/odoo \
    -v /$podname/config:/etc/odoo \
        localhost/al3nas/odoo:14.0.1
        
echo 'DONE !'