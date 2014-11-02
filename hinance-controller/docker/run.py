import boto
import logging
from boto import vpc as botovpc
from os import environ
from time import sleep

APP = 'hinance-controller'
REGION = 'us-east-1'
CIDR = '192.168.0.0/16'
IMAGE = 'ami-9eaa1cf6'
INSTANCE_TYPE = 't2.medium'
SLEEP = 10

def tag():
    return '%s-%s' % (APP, environ['APP_VERSION'])

def connect():
    return botovpc.connect_to_region(REGION,
        aws_access_key_id = environ['AWS_KEY'],
        aws_secret_access_key = environ['AWS_SECRET'])

def get_all(what, filters):
    def func(conn):
        for x in getattr(conn,'get_all_%s'%what)(filters=filters):
            return x
    return func

vpc = get_all('vpcs', {'tag:name': tag()})
subnet = get_all('subnets', {'tag:name': tag()})
key_pair = get_all('key_pairs', {'key-name': tag()})
sgroup = get_all('security_groups', {'group-name': tag()})
ires = get_all('instances', {'tag:name': tag(), 'instance-state-name': [
    'pending', 'running', 'shutting-down', 'stopping', 'stopped']})

def inst(conn):
    r = ires(conn)
    if r:
        return r.instances[0]

def create():
    conn = connect()
    if not vpc(conn):
        conn.create_vpc(CIDR).add_tag('name', tag())
    if not subnet(conn):
        conn.create_subnet(vpc(conn).id, CIDR).add_tag('name', tag())
    if not key_pair(conn):
        with open('/var/lib/%s/key.pem' % APP, 'w') as f:
            f.write(conn.create_key_pair(tag()).material)
    if not sgroup(conn):
        conn.create_security_group(tag(), tag(), vpc(conn).id)
    if not ires(conn):
        conn.run_instances(IMAGE, key_name=key_pair(conn).name,
            security_group_ids=[sgroup(conn).id], subnet_id=subnet(conn).id,
            instance_type=INSTANCE_TYPE).instances[0].add_tag('name', tag())
    conn.close()

def delete():
    conn = connect()
    if inst(conn):
        inst(conn).terminate()
        while inst(conn):
            sleep(SLEEP)
    if sgroup(conn):
        conn.delete_security_group(group_id=sgroup(conn).id)
    if key_pair(conn):
        conn.delete_key_pair(key_pair(conn).name)
    if subnet(conn):
        conn.delete_subnet(subnet(conn).id)
    if vpc(conn):
        conn.delete_vpc(vpc(conn).id)
    conn.close()

def main():
    create()
    delete()

logging.basicConfig(format='%(levelname)-8s %(asctime)-15s %(message)s')
logging.getLogger().setLevel(logging.DEBUG)

if __name__ == '__main__':
    main()
