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

### Secret variables

We try to keep as little secret variables as possible by design. For the sake of convenience, define the following secrets in your Github secrets section:

- `GOOGLE_APPLICATION_CREDENTIALS` = GCP service account credentials
- `GOOGLE_PROJECT` = GCP project ID
- `GOOGLE_REGION` = GCP project default region
- `GOOGLE_BUCKET` = GCP bucket for storing Terraform state

### Non-secret variables

For non-secret variables, simply edit/add them in the `.env` file, which gets sourced during pipeline runs, e.g.:

```dotenv
export TF_VAR_name="rpch-anaconda"
```

### Installation

Run the `day-0-apply` workflow in Gitub.

# TODOs
- Github pipelines to cache TF providers.
- In the future, think more about keeping pipelines DRY.
- Find a solution where all the following hold true at the same time:
  1) two sequential stages, e.g. `day-1` to run only after successful `day-0`
  2) second job can be triggered manually only when the first job succeeds
  3) first job produces a TF plan artifact that gets ingested by the second job
  4) trigger a workflow dispatch from non-main branch initially