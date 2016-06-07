Terraform helps create AWS resources.

To use these TF scripts make sure TerraForm is installed on your machine
`https://www.terraform.io/intro/getting-started/install.html`

Clone this repo:
`$ git clone git@github.com:WesleyCharlesBlake/terraform-existing-vpc.git`


Then validate

`$ terraform validate`

If no template errors are found you can run a plan:
`$ terraform plan`
This will show you how many resources will be created

When you are ready to deploy:

`$ terraform apply`

You will need to input certain variables at each prompt (such access keys/secrets , ami ID's etc)

When you are done with the hosts, please clean up:

`$ terraform plan -destroy`
This will show us which resources are going to be destroye

To apply this:
`$ terraform destroy`

This template creates 22 resources (multiple role EC2 instances, an ELB, provisioners from template file resources used for ec2 user_data and DNS entries in Route53)

Read my blog post to on Packer and TerraForm [here](http://blog.stratotechnology.com/packer-and-terraform/)