# infrastructure

> <picture>
>   <source media="(prefers-color-scheme: light)" srcset="https://github.com/Mqxx/GitHub-Markdown/blob/main/blockquotes/badge/light-theme/info.svg">
>   <img alt="Info" src="https://github.com/Mqxx/GitHub-Markdown/blob/main/blockquotes/badge/dark-theme/info.svg">
> </picture><br>
> This repo is an active WIP and the configuration/structure is a subject to change

This repo holds the configuration for RPCh infrastructure such as:

- Terraform manifests
- Dockerfiles
- Helm charts
- Kubernetes manifests
- ArgoCD applications

The repository aims to:
- Automate near 100% of all resources (infrastructure, services, applications)
- Utilize industry-standard tools and practices (orchestration, containers, gitops, security)
- Provide easy-to-use configuration

## Kubernetes cluster

### Preparation

Make sure you have:
- A Github account with escalated permissions to set secrets
- A GCP service account with escalated permissions to create resources
- A GCP storage bucket for storing Terraform state
- GCP APIs enabled:
  - `compute.googleapis.com`
  - `container.googleapis.com`
  - `dns.googleapis.com`
- A new RSA keypair with no passphrase for ArgoCD to access the Github repo. The public key of this keypair has to be then uploaded to the deploy keys of the repository; the private key has to be set as a secret variable `ARGOCD_CREDENTIALS_KEY`. You can generate the keypair by running:

```shell
ssh-keygen -b 2048 -t rsa -f /tmp/id_rsa -q -N "" -C rpch-anaconda
```

### Secret variables

We try to keep as little secret variables as possible by design. For the sake of convenience, define the following secrets in your Github secrets section:

- `GOOGLE_APPLICATION_CREDENTIALS` = GCP service account credentials
- `GOOGLE_PROJECT` = GCP project ID
- `GOOGLE_REGION` = GCP project default region
- `GOOGLE_BUCKET` = GCP bucket for storing Terraform state
- `ARGOCD_CREDENTIALS_KEY` = Base64-encoded ArgoCD credentials private key from the previously generated keypair.

### Non-secret variables

For non-secret variables, simply edit/add them in the `.env` file, which gets sourced during pipeline runs, e.g.:

```dotenv
export TF_VAR_name="rpch-anaconda"
export TF_VAR_domain="rpch.tech"
export TF_VAR_argocd_repo_url="git@github.com:Rpc-h/infrastructure.git"
export TF_VAR_argocd_credentials_url="git@github.com:Rpc-h"
```

### Installation

Run the `day-0-apply` workflow in Github to install `day-0` resources such as:
- GKE Kubernetes cluster and node pools
- IAM service accounts and bindings for the Kubernetes cluster
- VPC networks and firewall rules for the Kubernetes cluster

After successful completion of `day-0-apply`, run the `day-1-apply` workflow in Github to install `day-1` resources such as:
- ArgoCD helm chart and the initial ArgoCD app-of-apps
- IAM service accounts and bindings for `day-2` applications, e.g. `cert-manager`, `external-dns`, etc.

### Uninstallation

Run the `day-1-destroy` workflow in Github to destroy `day-1`. After successful completion of `day-1-destroy`, run the `day-0-destroy` workflow in Github to destroy `day-0`. Note that some of the `day-2` cloud provider resources created by your apps, such as load balancers and DNS entries, might interfere with the current destruction of `day-1` and `day-0`. Either make sure everything in `day-2` is uninstalled cleanly, or you might have to do remove the stuck resources manually.

### Applications

#### Authelia

To generate `authelia` password, run the following command:

```shell
export AUTHELIA_PASSWORD="your-password-here"
docker run authelia/authelia:latest authelia crypto hash generate argon2 --password ${AUTHELIA_PASSWORD}
```

# TODOs
- Github pipelines to cache TF providers.
- In the future, think more about keeping pipelines DRY.
- Have more complex comments for each step in a job, where required.
- Find a solution where all the following hold true at the same time:
  1) two sequential stages, e.g. `day-1` to run only after successful `day-0`
  2) second job can be triggered manually only when the first job succeeds
  3) first job produces a TF plan artifact that gets ingested by the second job
  4) trigger a workflow dispatch from non-main branch initially

# Notes

- One more reasons for having day-1: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#stacking-with-managed-kubernetes-cluster-resources