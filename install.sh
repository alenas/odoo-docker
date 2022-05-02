#!/bin/bash
podname=odoo

mkdir -p /$podname/data
mkdir -p /$podname/config
mkdir -p /$podname/odoo-addons
mkdir -p /$podname/vialaurea

mkdir -p /$podname/proxy

mkdir -p /$podname/db

if [ ! -f set-env-pwd.sh ]; then
    echo 'Generating random SQL passwords and saving to set-env.pwd.sh'
    . generate-mysql-pwd.sh
else
    . set-env-pwd.sh
fi

if [ ! -f /$podname/config/odoo.conf ]; then
    echo 'Copying odoo config...'
    cp odoo.conf /$podname/config/
    chmod 666 /$podname/config/odoo.conf
fi

if [ ! -f /$podname/proxy/traefik.yaml ]; then
    echo 'Copying proxy config...'
    cp ./etc/traefik/* /$podname/proxy/
    chmod -R 666 /$podname/proxy
fi


echo 'Creating pod: ' $podname
### create pod
podman pod create -n $podname --network=podman --hostname pir.lt \
    -p 80:80/tcp -p 443:443/tcp -p 8080:8080/tcp

echo 'Starting pod: ' $podname
#podman pod start $podname

echo 'Running DB container: ' $podname-db
### create db container
podman create --name $podname-db --pod $podname \
    --cgroups=disabled \
    -v /$podname/db:/var/lib/postgresql/data \
    -e POSTGRES_USER=odoo \
    -e POSTGRES_PASSWORD=$MYSQLPWD \
    -e POSTGRES_DB=postgres \
        docker.io/library/postgres:14-alpine

echo 'Running traefik reverse-proxy...'
podman create --name $podname-proxy --pod $podname \
    --cgroups=disabled \
    -v /$podname/proxy:/etc/traefik \
        docker.io/library/traefik:2.6

echo 'Running APP container: ' $podname-app
### create app container - run and then attach to
podman create --name $podname-app --pod $podname \
    --cgroups=disabled \
    -e HOST=127.0.0.1 \
    -e USER=odoo \
    -e PASSWORD=$MYSQLPWD \
    -v /$podname/data:/var/lib/odoo \
    -v /$podname/config:/etc/odoo \
    -v /$podname/odoo-addons:/mnt/extra-addons \
    -v /$podname/vialaurea:/mnt/vialaurea \
       localhost/al3nas/odoo:15.0.03.26
        
echo 'DONE !'