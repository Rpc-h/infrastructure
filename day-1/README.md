# Commons tools

```
make install-server env=staging
make install-server env=prod
make install-hoprd env=staging
make install-hoprd env=prod
make install-phttp-exit-app env=staging
make install-phttp-exit-app env=prod

make install-hoprd env=staging debug=true limit=hetzner-staging-alpha-4

make restart env=staging clean=false limit=hetzner-staging-alpha-11
make restart env=staging clean=true


make encrypt env=staging
make decrypt env=staging
make show env=staging

```

## Rollout Deployment

These commands show the sequence for a rollout deployment of new versions:

```
make restart env=prod limit=entry_node_a
make restart env=prod limit=phttp_exit_app_a
sleep 300
make restart env=prod limit=entry_node_b
make restart env=prod limit=phttp_exit_app_b
sleep 300
make restart env=prod limit=entry_node_c
make restart env=prod limit=phttp_exit_app_c
```
