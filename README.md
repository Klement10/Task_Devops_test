# Deploying a two-tier architecture in AWS using Terraform
![diagram](https://user-images.githubusercontent.com/99483337/223571381-e76ae52c-0383-463c-8b4a-395174195d9a.jpg)
+ Custom VPC with CIDR 10.0.0.0/16.
+ Two Public Subnets with CIDR 10.0.1.0/24 and 10.0.2.0/24 in different Availability Zones for high availability.
+ Two Private Subnets with CIDR 10.0.3.0/24 and 10.0.4.0/24 in different Availabilty Zones.
+ RDS MySQL instance (micro) in One of the Two Private Subnets.
+ One Application Load Balancer (External) — Internet facing, which will direct the traffic to the Public Subnets.
+ Two EC2 t3.micro instance in each Public Subnet and Private Subnet
+ Nat Gateway and elastic ip
-----
## Requirements
+ Terraform v1.3.9
+ Ansible 2.12.3
+ AWS Cli v2
+ Git 2.30.2

-----
**After installing the above applications**

```
#mandatory config before executing teraform init
$ aws configure - [--profile profile-name] #Username in AWS
AWS Access Key ID [None]: accesskey      #Your Access key
AWS Secret Access Key [None]: secretkey  #Your Secret key 
Default region name [None]: us-west-2    #the region where your infrastructure will be deployed
Default output format [None]:json        #file format
```

**Terraform**

```
$ terraform init 

#Is the first command that should be run. 
#As the name indicates it initializes a working directory containing Terraform configuration files.

$ terraform validate

#Validates the configuration files in a directory
#It is primarily useful for general verification of reusable modules, including the correctness of attribute names and value types

$ terraform plan 

#Run  to show the execution plan for the resources being created.

$ terraform apply

#Run terraform apply and type yes when prompted to execute the plan.

$ terraform state list

#Run, to see the list of all the AWS resources that are created.

$ terraform destroy 

#Run,  from the terminal to remove all the AWS resources not to incur any AWS charges!
```

**Ansible**

[host.txt](https://github.com/Klement10/Task_Devops_test/blob/main/ansible-test/docker.yml)
In the host.txt file, replace the value of $ ansible_host= public ip EC2-1

```
$ ansible playbook docker.yml 

# Execute to launch the playbook and install Docker & Docker compose 
```

**Wordpress**

After install Docker & Docker compose on ES2
Install Git or copy text on file [compose.yaml](https://github.com/Klement10/Task_Devops_test/blob/main/wordpress/compose.yaml)
And replace the value with your own
```
environment:
- WORDPRESS_DB_HOST=terraform-20230307195909837700000003.cciqztcfdbjp.us-east-1.rds.amazonaws.com # example endpoint RDS connect to DB
```

```
$ docker compose up -d

ubuntu@ip-10-0-1-192:~/wordpress$ sudo docker-compose up -d
Creating network "wordpress_default" with the default driver
Pulling wordpress (wordpress:latest)...
Creating wordpress_wordpress_1 ... done
```

Docker compose run container
```
$sudo docker-compose ps

ubuntu@ip-10-0-1-192:~/wordpress$ sudo docker-compose ps
        Name                       Command               State                Ports              
------------------------------------------------------------------------------------------------
wordpress_wordpress_1   docker-entrypoint.sh apach ...   Up      0.0.0.0:80->80/tcp,:::80->80/tcp

```

Stop and remove the containers
```
$ sudo docker compose down
```
