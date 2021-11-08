# Terraform SSP EKS Patterns

Welcome to the patterns repository for the Amazon [EKS Accelerator for Terraform](https://github.com/aws-samples/aws-eks-accelerator-for-terraform) framework. This repository contains a number of examples for how you can leverage the framework to deploy multi-tenant environments on EKS with a variety of configurations. 

## Patterns 

The individual patterns can be found in the `examples` directory. 

## Documentation

Please refer to the EKS Accelerator for Terraform [documentation directory](https://github.com/aws-samples/aws-eks-accelerator-for-terraform/blob/main/docs/index.md) for complete project documentation.

## Prerequisites:

Ensure that you have installed the following tools on your machine.

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
3. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
4. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Usage

Clone the repository 

```
git clone git@github.com:aws-samples/terraform-ssp-eks-patterns.git
```

Navigate into one of the example directories and run `terraform init`

```
cd examples/1-eks-cluster-with-new-vpc 
terraform init
```

Run Terraform plan to verify the resources created by this execution. 

```
export AWS_REGION="eu-west-1"   # Select your own region
terraform plan

```

Deploy the pattern

```
terraform apply
```

Enter `yes` to apply.

## Validation

The name of your EKS cluster can be extracted from the Terraform output or from the AWS Console. Run the following command to update `~/.kube/config` file locally with cluster details and certificate.
r
```
aws eks --region $AWS_REGION update-kubeconfig --name <cluster-name>
```

Verify your `kubeconfig` is updated by listing nodes in your cluster. 

```
kubectl get nodes
```

Additionally, list pods in the `kube-system` namespace.

```
kubectl get pods -n kube-system
```

## Cleanup 

To clean up your environment

```
terraform destroy
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
