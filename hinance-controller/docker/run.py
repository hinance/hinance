import boto
import logging
from boto import vpc as botovpc
from os import environ

APP = 'hinance-controller'
REGION = 'us-east-1'
CIDR = '192.168.0.0/16'

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

def create():
    logging.info('Creating.')
    conn = connect()
    if not vpc(conn):
        logging.info('Creating VPC.')
        conn.create_vpc(CIDR).add_tag('name', tag())
    while vpc(conn).state != 'available':
        logging.info('Waiting for VPC.')
        sleep(10)
    if not subnet(conn):
        logging.info('Creating subnet.')
        conn.create_subnet(vpc(conn).id, CIDR).add_tag('name', tag())
    if not key_pair(conn):
        logging.info('Creating key pair.')
        with open('/var/lib/%s/key.pem' % APP, 'w') as f:
            f.write(conn.create_key_pair(tag()).material)
    conn.close()
    logging.info('Done creating.')

def delete():
    logging.info('Deleting.')
    conn = connect()
    if key_pair(conn):
        logging.info('Deleting key pair.')
        conn.delete_key_pair(key_pair(conn).name)
    if subnet(conn):
        logging.info('Deleting subnet.')
        conn.delete_subnet(subnet(conn).id)
    if vpc(conn):
        logging.info('Deleting VPC.')
        conn.delete_vpc(vpc(conn).id)
    conn.close()
    logging.info('Done deleting.')

def main():
    create()
    delete()

logging.basicConfig(format='%(levelname)-8s %(asctime)-15s %(message)s')
logging.getLogger().setLevel(logging.INFO)

if __name__ == '__main__':
    main()
