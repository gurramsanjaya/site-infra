# Kubernetes Infrastructure Deployment

This repository provides infrastructure-as-code for provisioning and configuring a Kubernetes environment using Helm charts and Terraform modules.

## 📁 Directory Structure

```plaintext
.
├── helm/
│   ├── install-script.sh         # Installation helper script for Helm charts
│   ├── cert-manager-wrapper/     # Helm chart for cert-manager
│   ├── infra/                    # Helm chart for core infrastructure (gateway, issuer)
│   ├── nginx-gateway-fabric-wrapper/ # Helm chart for Fabric ingress gateway
│   └── test/                     # Helm chart for testing/development
└── terraform/
    ├── main.tf                   # Terraform configuration for cloud resources
    ├── variables.tf              # Terraform variable definitions
    └── versions.tf               # Terraform version constraints
```

## 🚀 Prerequisites

- [Terraform](https://www.terraform.io/) (v1.x) or [OpenTofu](https://opentofu.org/) (v1.x) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed and configured
- [Helm 4](https://helm.sh/) installed
- Access to a Kubernetes cluster with sufficient privileges


## 🔧 Terraform Provisioning

Initialize and apply Terraform to provision required cloud infrastructure:
```bash
cd terraform && terraform init
terraform apply
```

> Main configuration: [`terraform/main.tf`](terraform/main.tf:1)

## ⚙️ Helm Installation


Update [`helm/infra/values-override.yaml`](helm/infra/values-override.yaml:1) with site-specific settings as needed (email, hostname and their corresponding tls secrets, publicFacingIpAddressName, annotations etc.).

Run the installation script which deploys all required Helm charts and configures Terraform using `tofu` by default. To use the Terraform CLI instead, set the `TERRAFORM_BIN` environment variable:

```bash
bash helm/install-script.sh
```

Or override the default binary:

```bash
TERRAFORM_BIN=terraform bash helm/install-script.sh
```

> Script reference: [`helm/install-script.sh`](helm/install-script.sh:1)

## 📝 Helm Charts Overview

- **Fabric Ingress Gateway**: NGINX Gateway for Fabric network
  > Chart definition: [`helm/nginx-gateway-fabric-wrapper/Chart.yaml`](helm/nginx-gateway-fabric-wrapper/Chart.yaml:1)
- **cert-manager**: Configuration for certificate management
  > Chart definition: [`helm/cert-manager-wrapper/Chart.yaml`](helm/cert-manager-wrapper/Chart.yaml:1)
- **Core Infrastructure**: API Gateway, HTTP routes, ClusterIssuer
  > Chart definition: [`helm/infra/Chart.yaml`](helm/infra/Chart.yaml:1)
- **Test Environment**: Sandbox deployment settings
  > Chart definition: [`helm/test/Chart.yaml`](helm/test/Chart.yaml:1)

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests to improve documentation, add features, or fix bugs.

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
