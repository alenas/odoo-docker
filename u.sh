#!/bin/bash
podman pod stop odoo 2>/dev/null
podman pod rm odoo 2>/dev/null
rm /odoo/data/odoo.log
podman play kube odoo.yml