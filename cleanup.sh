#!/bin/bash
podname=odoo

systemctl stop pod-$podname
systemctl disable pod-$podname
systemctl disable container-$podname-app
systemctl disable container-$podname-db
systemctl disable container-$podname-proxy

# in case pod was started not from systemctl
podman pod stop $podname

rm /odoo/data/odoo.log
podman pod rm $podname
podman rm $podname-proxy
podman rm $podname-db
podman rm $podname-app

echo "Finished CLEANUP ..."