import boto3
import paramiko
# This lambda function received SNS notification when EC2 instance terminates. 
# And on termination it rotates the logs in that ec2 by doing ssh to that box.
def ecs_asg_lifecycle_handler(event, context):
    #Get IP addresses of EC2 instances
    ec2_client = boto3.client('ec2')
    msg = event['Records'][0]['Sns']['Message']
    instance_id = json.loads(msg)["EC2InstanceId"]
    ec2_response = ec2_client.describe_instances(InstanceIds=[instance_id])
    private_ip = ec2_response['Reservations'][0]['Instances'][0]['PrivateIpAddress']

    s3_client = boto3.client('s3')
    #Download private key file from secure S3 bucket
    s3_client.download_file('phantom-ci-packages','ansible/phantom_ansible', '/tmp/keyname.pem')

    k = paramiko.RSAKey.from_private_key_file("/tmp/keyname.pem")
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print "Connecting to " + private_ip
    c.connect( hostname = private_ip, username = "ubuntu", pkey = k )
    print "Connected to " + private_ip

    commands = [
        "/usr/sbin/logrotate --force /etc/logrotate.conf",
        "ls -al",
        "hostname"
        ]
    for command in commands:
        print "Executing {}".format(command)
        stdin , stdout, stderr = c.exec_command(command)
        print stdout.read()
        print stderr.read()
