#!/bin/bash

##########################################################################################################
#  This script was developed to deploy the whole infrastructure for you.                                 #
#                                                                                                        #
#  It will ask you the data to input in a terraform.tfvars to feed all terrform modules variables and    #
#  deploy the applications for you adn install terraform if not installed previously                     #
#                                                                                                        #
#  TO USE THIS PROGRAM YOU MUST HAVE A MINIMUM KNOWLEDGE OF AWS USAGE                                    #
#                                                                                                        #
##########################################################################################################

echo "This will delete your terraform.tfvars file if it already exists.
Press enter to continue! | CTRL + C to cancel"
trap read DEBUG

if [ ! -f /usr/local/bin/terraform ]; then
    wget https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
    unzip terraform_0.11.14_linux_amd64.zip
    mv terraform /usr/local/bin/terraform
    rm terraform_0.11.14_linux_amd64.zip
else
    echo "You already have terraform installed. If it's 0.12+ version, please uninstall it first or the apply will not work."
fi

if [ -f terraform.tfvars ]; then
    rm terraform.tfvars
fi

echo "Enter your ssh PUBLIC key: 
e.g ssh-rsa AAAAaaadpodJPPFOIJOIADJHOIHAoihdoaodhQDNu8JQkJGy63qGlksV+54Nc5yiqkSUB431oG298rinT0KZ/2Z2TNqD8ECfUFoMGaNhaojsIhuhdiAOohdaoidjzkzkPGHvusGcbiZRMKmyT46JleJOAJFSJD8jahdapdqdoWfB"
read ENTRY
echo "ssh_key = \"$ENTRY\"" > terraform.tfvars

echo "Enter your AWS Account ID: 
e.g 39143826825"
read ENTRY
echo "acc_id = \"$ENTRY\"" >> terraform.tfvars

echo "Enter your AMI ID <recommended ubuntu>: 
e.g ami-026c8acd92718196b"
read ENTRY 
echo "ami_id = \"$ENTRY\"" >> terraform.tfvars

echo "Enter your SSH key name: 
e.g id_rsa"
read ENTRY 
echo "ssh_key_name = \"$ENTRY\"" >> terraform.tfvars

echo "Enter your AWS access key id: 
e.g PKLAVIDJPPH5RDMU4"
read ENTRY 
echo "access_key_id = \"$ENTRY\"" >> terraform.tfvars

echo "Enter your AWS secret access key: 
e.g r2NyY3JDkahDrbnx2vskfk3utndhrojf0M7cUz7fW"
read ENTRY 
echo "secret_access_key = \"$ENTRY\"" >> terraform.tfvars

echo "Enter your IP address: 
e.g 205.32.45.80"
read ENTRY 
echo "my_ip = \"$ENTRY\"" >> terraform.tfvars

echo "Enter the CIDR range: 
e.g 32"
read ENTRY 
echo "cidr_range = \"$ENTRY\"" >> terraform.tfvars

echo "Enter the AWS Availability Zone: 
e.g us-east-1"
read ENTRY 
echo "aws_az = \"$ENTRY\"" >> terraform.tfvars

echo "Enter the Transmission server password: 
e.g 12345678"
read ENTRY 
echo "transmission_passwd = \"$ENTRY\"" >> terraform.tfvars

terraform init
echo yes | terraform apply