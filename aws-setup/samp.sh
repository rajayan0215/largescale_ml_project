echo "#!/bin/bash" > $name-remove.sh # overwrite existing file

echo aws ec2 delete-security-group --group-id $securityGroupId >> $name-remove.sh
echo aws ec2 disassociate-route-table --association-id $routeTableAssoc >> $name-remove.sh
echo aws ec2 delete-route-table --route-table-id $routeTableId >> $name-remove.sh
echo aws ec2 detach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId >> $name-remove.sh
echo aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId >> $name-remove.sh
echo aws ec2 delete-subnet --subnet-id $subnetId >> $name-remove.sh
echo aws ec2 delete-vpc --vpc-id $vpcId >> $name-remove.sh

echo rm -f ~/aws_scripts/authorize-current-ip ~/aws_scripts/list-instances ~/aws_scripts/deauthorize-ip ~/aws_scripts/list-authorized-ips ~/aws_scripts/cancel-open-spot-instance-requests ~/aws_scripts/list-open-spot-instance-requests ~/aws_scripts/list-active-spot-instance-requests >> $name-remove.sh
echo rm -f $name-remove.sh $name-vars.sh >> $name-remove.sh
chmod +x $name-remove.sh

# Save variables
echo "#!/bin/bash" > $name-vars.sh # overwrite existing file
echo export subnetId=$subnetId >> $name-vars.sh
echo export securityGroupId=$securityGroupId >> $name-vars.sh
echo export routeTableId=$routeTableId >> $name-vars.sh
echo export envName=$name >> $name-vars.sh
echo export vpcId=$vpcId >> $name-vars.sh
echo export internetGatewayId=$internetGatewayId >> $name-vars.sh
echo export subnetId=$subnetId >> $name-vars.sh
echo export routeTableAssoc=$routeTableAssoc >> $name-vars.sh
echo export availabilityZone=$availabilityZone >> $name-vars.sh

if [ ! -d ~/aws_scripts ]
then
  mkdir ~/aws_scripts
fi

echo echo \$\(aws ec2 describe-security-groups --query \'SecurityGroups[?GroupId==\`$securityGroupId\`].IpPermissions[*].[IpRanges]\' --output text\) > ~/aws_scripts/list-authorized-ips
echo authorizedIp=\$\(aws ec2 describe-security-groups --query \'SecurityGroups[?GroupId==\`$securityGroupId\`].IpPermissions[*].[IpRanges][0]\' --output text\) > ~/aws_scripts/deauthorize-ip
echo aws ec2 revoke-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr '$authorizedIp' >> ~/aws_scripts/deauthorize-ip
echo aws ec2 revoke-security-group-ingress --group-id $securityGroupId --protocol tcp --port 8888-8898 --cidr '$authorizedIp' >> ~/aws_scripts/deauthorize-ip
echo externalIP='$(dig +short myip.opendns.com @resolver1.opendns.com)' > ~/aws_scripts/authorize-current-ip
echo aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr '$externalIP'/32 >> ~/aws_scripts/authorize-current-ip
echo aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 8888-8898 --cidr '$externalIP'/32 >> ~/aws_scripts/authorize-current-ip
echo aws ec2 describe-instances --query "'Reservations[*].Instances[*].{ID:InstanceId, type:InstanceType, state:State.Name, IP: PublicIpAddress, DNSName: PublicDnsName}'" --output text > ~/aws_scripts/list-instances
echo export spotInstanceRequestIds=\$\(aws ec2 describe-spot-instance-requests --query "'SpotInstanceRequests[?State==\`open\`].[SpotInstanceRequestId]'" --output text\) > ~/aws_scripts/cancel-open-spot-instance-requests
echo aws ec2 cancel-spot-instance-requests --spot-instance-request-ids \$spotInstanceRequestIds >> ~/aws_scripts/cancel-open-spot-instance-requests
echo aws ec2 describe-spot-instance-requests --query "'SpotInstanceRequests[?State==\`open\`].{type:[LaunchSpecification][0].[InstanceType][0],status:Status,requestId:SpotInstanceRequestId,price:SpotPrice}'" > ~/aws_scripts/list-open-spot-instance-requests
echo aws ec2 describe-spot-instance-requests --query "'SpotInstanceRequests[?State==\`active\`].{type:[LaunchSpecification][0].[InstanceType][0],status:Status,requestId:SpotInstanceRequestId,price:SpotPrice}'" > ~/aws_scripts/list-active-spot-instance-requests

chmod +x ~/aws_scripts/authorize-current-ip ~/aws_scripts/list-instances ~/aws_scripts/deauthorize-ip ~/aws_scripts/list-authorized-ips ~/aws_scripts/cancel-open-spot-instance-requests ~/aws_scripts/list-open-spot-instance-requests ~/aws_scripts/list-active-spot-instance-requests

