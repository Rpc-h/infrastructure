# Commons tools

```
make install-server env=staging
make install-server env=prod
make install-hoprd env=staging
make install-hoprd env=prod
make install-exit-node env=staging
make install-exit-node env=prod

make install-hoprd env=staging debug=true limit=hetzner-staging-alpha-4

make restart env=staging clean=false limit=hetzner-staging-alpha-11
make restart env=staging clean=true

make encrypt env=staging
make decrypt env=staging
make show env=staging

```