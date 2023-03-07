# Deploying a two-tier architecture in AWS using Terraform
![diagram](https://user-images.githubusercontent.com/99483337/223571381-e76ae52c-0383-463c-8b4a-395174195d9a.jpg)
+ Custom VPC with CIDR 10.0.0.0/16.
+ Two Public Subnets with CIDR 10.0.1.0/24 and 10.0.2.0/24 in different Availability Zones for high availability.
+ Two Private Subnets with CIDR 10.0.3.0/24 and 10.0.4.0/24 in different Availabilty Zones.
+ RDS MySQL instance (micro) in One of the Two Private Subnets.
+ One Application Load Balancer (External) — Internet facing, which will direct the traffic to the Public Subnets.
+ Two EC2 t3.micro instance in each Public Subnet and Private Subnet
+ Nat Gateway and elastic ip
