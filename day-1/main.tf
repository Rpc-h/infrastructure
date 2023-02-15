#TODO - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam#google_project_iam_binding
#Looks like GCP is yolo deleting or assigning service accounts to roles...
resource "google_project_iam_binding" "main" {
  members = [
    "serviceAccount:${google_service_account.cert_manager.email}",
    "serviceAccount:${google_service_account.external_dns.email}"
  ]
  role = "roles/dns.admin"
  #Not inferred from the provider
  project = var.google_project
}

#Disable the built-in default storage class
resource "kubernetes_annotations" "main" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "standard-rwo"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

#Create a new default storage class
resource "kubernetes_storage_class" "main" {
  metadata {
    name = "main"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "kubernetes.io/gce-pd"
  reclaim_policy      = "Retain"
  parameters = {
    type = "pd-standard"
  }

  allow_volume_expansion = true

  mount_options = [
    "file_mode=0700",
    "dir_mode=0777",
    "mfsymlinks",
    "uid=1000",
    "gid=1000",
    "nobrl",
    "cache=none"
  ]

  depends_on = [
    kubernetes_annotations.main
  ]
}