#!/bin/bash 

IP=$(curl ifconfig.me)
echo $IP

SG_ID="YOUR SECURITY GROUP ID HERE"


SG_DESCRIPTION=$(aws ec2 describe-security-groups --group-ids $SG_ID)

EXISTS=$(node<<EOF
let exists = false;
let security_groups = ($SG_DESCRIPTION).SecurityGroups;
let permissions = security_groups[0].IpPermissions;
let ssh_permission = permissions.find(p => p.FromPort == 22 && p.ToPort == 22);
if(typeof ssh_permission !== 'undefined'){
    let found_range = ssh_permission.IpRanges.find(ip_des => ip_des.CidrIp.indexOf("$IP") !== -1);
    exists = typeof found_range !== 'undefined';
}
console.log(exists)
EOF)

echo "SG EXISTS: $EXISTS"
if [ $EXISTS == "false" ]
then
    echo "IP NOT ALLOWED YET"
    echo "ADDING IP: $IP"
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr $IP/32
    echo "$IP added"
    aws ec2 describe-security-groups --group-ids $SG_ID
else
    echo "IP ALREADY ALLOWED"
fi
