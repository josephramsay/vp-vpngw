import boto3, botocore
import sys
import json
import jq


#REGION = 'us-west-1'

class Settings():
    def __init__(self):
        self.session = boto3.Session(profile_name='default')
        self.config = botocore.config.Config(
            region_name = self.session.region_name,
            signature_version = 'v4',
            retries = {
                'max_attempts': 10,
                'mode': 'standard'
            }
        )
        self.ec2 = boto3.client('ec2', config=self.config)

    def commit(self):
        self.session.commit()
    

class VPC:
    VPCName = 'vp-vpn'
    SGName = 'vp-vpn-sg'
    CBlock = '172.16.1.0/24'
    DestCBlock = '0.0.0.0/0'

    IngressRules = [
        {'CidrIp':DestCBlock,'IpProtocol':'tcp','FromPort':-1,'ToPort':-1},
        {'CidrIp':DestCBlock,'IpProtocol':'tcp','FromPort':-1,'ToPort':-1},
        {'CidrIp':DestCBlock,'IpProtocol':'tcp','FromPort':-1,'ToPort':-1},
        {'CidrIp':DestCBlock,'IpProtocol':'tcp','FromPort':-1,'ToPort':-1},
    ]
    def _init__(self):
        self.s = Settings()

    def createVpc(self):
        sys.exit()
        # create VPC
        if not self.s.ec2.Vpc(self.VPCName):
            self.vpc = self.ec2.create_vpc(CidrBlock=self.CBlock)
        # we can assign a name to vpc, or any resource, by using tag
        self.vpc.create_tags(Tags=[{"Key": "Name", "Value": self.VPCName}])
        self.vpc.wait_until_available()
        print(self.vpc.id)

        
        # create then attach internet gateway
        if not self.ec2.get_internet_gateway():
            self.ig = self.ec2.create_internet_gateway()
            self.vpc.attach_internet_gateway(InternetGatewayId=self.ig.id)
        print(self.ig.id)

        # create a route table and a public route
        self.route_table = self.vpc.create_route_table()
        self.route = self.route_table.create_route(
            DestinationCidrBlock=self.DestCBlock,
            GatewayId=self.ig.id
        )
        print(self.route_table.id)

        # create subnet
        self.subnet = self.ec2.create_subnet(CidrBlock=self.CBlock, VpcId=self.vpc.id)
        print(self.subnet.id)

        # associate the route table with the subnet
        self.route_table.associate_with_subnet(SubnetId=self.subnet.id)

        # Create sec group
        self.sec_group = self.ec2.create_security_group(
            GroupName=self.SGName, Description=self.SGName.upper()+' Security Group', VpcId=self.vpc.id)
        for rule in self.IngressRules:
            self.sec_group.authorize_ingress(rule)
        print(self.sec_group.id)

        '''
        # find image id ami-835b4efa / us-west-2
        # Create instance
        instances = ec2.create_instances(
            ImageId='ami-835b4efa', InstanceType='t2.micro', MaxCount=1, MinCount=1,
            NetworkInterfaces=[{'SubnetId': subnet.id, 'DeviceIndex': 0, 'AssociatePublicIpAddress': True, 'Groups': [sec_group.group_id]}])
        instances[0].wait_until_running()
        print(instances[0].id)
        '''

class Test:
    def __init__(self):
        pass

    def testconn(self):
        s = Settings()
        print (s.session.region_name)
        print (s.session.get_credentials())
        print (
            jq.compile('.Vpcs[].VpcId').input(json.dumps(s.ec2.describe_vpcs(),indent=2)).text()
        )
        print ([v for v in s.ec2.describe_vpcs().Vpcs.VpcId])

def main():

    t = Test()
    t.testconn()

    
    
if __name__ == '__main__':
    main()
