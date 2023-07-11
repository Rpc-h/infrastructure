# infrastructure

This repo holds the configuration for RPCh infrastructure such as:

- Terraform manifests
- Ansible roles

## Notes

- To get the outputs from Terraform with the IPv4 addresses, you can use the following command:

```shell
terraform output -json main | jq -r '.[]' | sort -n
```

- To run the Ansible playbook, use the following command:

```shell
ansible-playbook -i hosts install.yaml
```