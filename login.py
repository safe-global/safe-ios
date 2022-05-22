import boto3
from warrant.aws_srp import AWSSRP

client = boto3.client('cognito-idp', region_name='us-west-2')
aws = AWSSRP(username='5K7bgJnGeJJbEdmebYiJbBdSCC9Xkoof', password='3uCa9fDjQAzt4gA1rc8AW1vijfNLZQPucQoRak1e8M3UFNv1oUnqR7MEo5wU1xtX', pool_id='us-west-2_iLmIggsiy', client_id='1bpd19lcr33qvg5cr3oi79rdap', client=client)
tokens = aws.authenticate_user()
print(client.list_user_pool_clients(UserPoolId='us-west-2_iLmIggsiy'))
