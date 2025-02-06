# vpc365

## Create vpc with security groups, Internet Gateway and NAT gateway with Terrafrom

### Infrastructure elmets to create
- VPC with two public and private subnets
- Route table for each subnet
- Security group that allows ports 80 and 443 from the internet
- ELB listening on ports 80 and 443
- Route53 hosted zone with a CNAME entry for the ELB
- AWS API

## Python script to show used services for a given time period

### The script will perform following actions:
- List the AWS services used region wise.
- List each service in detail, like EC2, R
### Usage: get_usage_per_region.py [-h] --start-date START_DATE --end-date END_DATE [--detailed] [--show-cost]
- Date Format: YYYY-mm-dd
- Optional argument --detailed - list each service in details
- Optional argument --show-cost - list each service with cost

