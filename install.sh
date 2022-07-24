#!/bin/bash
podname=odoo
pod_domain=test.pir.lt
odoo_version=14.0.06.16

container_options="--cgroups=disabled"

mkdir -p /$podname/data
mkdir -p /$podname/config
mkdir -p /$podname/odoo-addons
mkdir -p /$podname/vialaurea

mkdir -p /$podname/proxy

mkdir -p /$podname/db

if [ ! -f set-env-pwd.sh ]; then
    echo 'Generating random SQL passwords and saving to set-env.pwd.sh'
    . etc/generate-mysql-pwd.sh
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
### create pod --network=podman
podman pod create -n $podname --hostname $pod_domain \
    -p 80:80/tcp -p 443:443/tcp -p 8080:8080/tcp

echo 'Creating DB container: ' $podname-db
### create db container
podman create --name $podname-db --pod $podname \
    $container_options \
    -v /$podname/db:/var/lib/postgresql/data:U \
    -e POSTGRES_USER=odoo \
    -e POSTGRES_PASSWORD=$MYSQLPWD \
    -e POSTGRES_DB=postgres \
        docker.io/library/postgres:13-alpine

echo 'Creating traefik reverse-proxy...'
podman create --name $podname-proxy --pod $podname \
    $container_options \
    -v /$podname/proxy:/etc/traefik:U \
        docker.io/library/traefik:2.7

echo 'Creating APP container: ' $podname-app
### create app container - run and then attach to
podman create --name $podname-app --pod $podname \
    $container_options \
    -e HOST=127.0.0.1 \
    -e USER=odoo \
    -e PASSWORD=$MYSQLPWD \
    -v /$podname/data:/var/lib/odoo:U \
    -v /$podname/config:/etc/odoo:U \
    -v /$podname/odoo-addons:/mnt/extra-addons:U \
    -v /$podname/vialaurea:/mnt/vialaurea:U \
       localhost/al3nas/odoo:$odoo_version
        
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