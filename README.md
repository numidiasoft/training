# Training
Blue Green AWS and Azure use cases

The project is devided to several branches, each branch represent a step

### Requirements

* An AWS account & the AWS CLI
* An Azure account & the AZ CLI
* terraform
* packer
* yarn

 

### Step 1

Step one creates networks and security rules

To execute the step 1

```shell
> cd providers/aws/terraform/
> git checkout step-1
> terraform init
> terraform apply
```

### Step 2

Step one creates an packer image and deploy a web application behind a load balancer

To execute the step 2

```shell
> cd providers/aws/packer/app
> yarn install
> cd providers/aws/packer/
> git checkout step-2
> packer build ubuntu.json
> # copy the generated image-id to the aws_ami resource in the blue.tf file
> terraform init
> terraform apply
```

It should outputs the dns name of the new load balancer

### Step 3

Step three creates a packer image and deploy a new version of the web application behind a new load balancer

To execute the step 3

```shell
> cd providers/aws/packer/app
> yarn install
> cd providers/aws/packer/
> git checkout step-3
> modify the server.js file
> packer build ubuntu.json
> # copy the generated image-id to the aws_ami resource in green.tf file 
> terraform init
> terraform apply
```

It should outputs the dns name of the new load balancer

### Step 4

Add a continuous integration pipeline

To execute the step 4, create a pull request to trigger a build

