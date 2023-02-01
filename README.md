# infrastructure

This repo holds the configuration for RPCh infrastructure such as:

- Terraform manifests
- Dockerfiles
- Helm charts
- Kubernetes manifests
- ArgoCD applications

## Deployment on core staging k8s cluster

- Install `kubectl` and `helm`.
- Make sure you can connect to the core staging cluster, e.g. by executing `kubectl get nodes`.
- Some variables, for example, `DB_CONNECTION_URL` are secret and will be shared individually. When you acquire the access, make sure you export the variables like `export DB_CONNECTION_URL="some-value-here"`.
- Switch to the correct context using `kubectl config use-context some-context-here`.
- Edit the `helm.sh` accordingly and finally execute `./helm.sh`.