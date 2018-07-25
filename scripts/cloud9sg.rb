#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'uri'

region = "us-east-1"
service = "CLOUD9"

r = Net::HTTP.get(URI::parse('https://ip-ranges.amazonaws.com/ip-ranges.json'))

rulenum = 0
puts <<EOH
---
AWSTemplateFormatVersion: '2010-09-09'
Description: Stack that creates security groups for allowing ssh from
  #{service} in the #{region} region
Parameters:
    VpcId:
        Description: The ID of the VPC where the SecurityGroup will be created
        Type: String
Resources:
EOH

rheader = <<EOH
    Type: "AWS::EC2::SecurityGroup"
    Properties:
      VpcId: !Ref VpcId
      GroupDescription: "Enable SSH access from #{service} in #{region} region"
      SecurityGroupIngress:
EOH

d = JSON::load(r)
added = 0
d["prefixes"].each do |p|
  if p["region"] == region && p["service"] == service && p["ip_prefix"]
    if added % 50 == 0
      puts "  USEastCloud9SecurityGroup#{rulenum}:"
      puts rheader
      rulenum += 1
    end
    added += 1
    prefix = p["ip_prefix"]
puts <<EOR
      - IpProtocol: "tcp"
        FromPort: "22"
        ToPort: "22"
        CidrIp: "#{prefix}"
EOR
  end
end
puts <<EOF
# Added #{added} entries
Outputs:
EOF
rules = rulenum - 1
for rule in 0..rules
puts <<EOF
  UsEastCloud9SSHSG#{rule}:
    Description: Security Group Allowing SSH from #{region} #{service}
    Value: !Ref USEastCloud9SecurityGroup#{rule}
EOF
end