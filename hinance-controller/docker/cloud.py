import boto
import logging
import optparse
from boto import vpc as botovpc
from os import environ
from time import sleep

APP = 'hinance-controller'
REGION = 'us-east-1'
CIDR = '192.168.0.0/16'
IMAGE = 'ami-9eaa1cf6'
INSTANCE_TYPE = 't2.medium'
SLEEP = 10

#WARNING:
# Current implementation will wipe out all your elastic IPs!

#TODO:
# Remove dances with elastic IP and use auto-map public IP on instance launch,
# when boto implements relevant IP.
# http://stackoverflow.com/questions/25977048/how-to-modify-auto-assign-public-ip-on-subnet-with-boto
# http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-ModifySubnetAttribute.html 
# https://github.com/boto/boto/issues/2646

def tag():
    return '%s-%s' % (APP, environ['APP_VERSION'])

def connect():
    return botovpc.connect_to_region(REGION,
        aws_access_key_id = environ['AWS_KEY'],
        aws_secret_access_key = environ['AWS_SECRET'])

def get_all(what, filters=None):
    def func(conn):
        return getattr(conn,'get_all_%s'%what)(filters=filters)
    return func

vpcs = get_all('vpcs', {'tag:Name': tag()})
subnets = get_all('subnets', {'tag:Name': tag()})
gates = get_all('internet_gateways', {'tag:Name': tag()})
key_pairs = get_all('key_pairs', {'key-name': tag()})
sgroups = get_all('security_groups', {'group-name': tag()})
irsvs = get_all('instances', {'tag:Name': tag(), 'instance-state-name': [
    'pending', 'running', 'shutting-down', 'stopping', 'stopped']})
addrs = get_all('addresses')

def insts(conn):
    return [i for r in irsvs(conn) for i in r.instances]

def rtabs(conn):
    return [r for v in vpcs(conn) for r in conn.get_all_route_tables(
            filters={'vpc_id': v.id})]

def create():
    logging.info('Creating.')
    conn = connect()
    if not vpcs(conn):
        conn.create_vpc(CIDR).add_tag('Name', tag())
        while not vpcs(conn):
            logging.info('Creating VPC...')
            sleep(SLEEP)
    if not subnets(conn):
        conn.create_subnet(vpcs(conn)[0].id, CIDR).add_tag('Name', tag())
        while not subnets(conn):
            logging.info('Creating subnet...')
            sleep(SLEEP)
    for net in subnets(conn):
        for rtab in rtabs(conn):
            if net.id not in [a.subnet_id for a in rtab.associations]:
                conn.associate_route_table(rtab.id, net.id)
    if not key_pairs(conn):
        with open('/var/lib/%s/key.pem' % APP, 'w') as f:
            f.write(conn.create_key_pair(tag()).material)
        while not key_pairs(conn):
            logging.info('Creating key pair...')
            sleep(SLEEP)
    if not sgroups(conn):
        conn.create_security_group(tag(), tag(), vpcs(conn)[0].id)
        while not sgroups(conn):
            logging.info('Creating security group...')
            sleep(SLEEP)
    for sgroup in sgroups(conn):
        if ('tcp', '0', '65535') not in [
        (r.ip_protocol, r.from_port, r.to_port) for r in sgroup.rules]:
            sgroup.authorize(ip_protocol='tcp', from_port=0, to_port=65535,
                             cidr_ip='0.0.0.0/0')
    if not gates(conn):
        conn.create_internet_gateway().add_tag('Name', tag())
        while not gates(conn):
            logging.info('Creating internet gateway...')
            sleep(SLEEP)
    for gate in gates(conn):
        for vpc in vpcs(conn):
            if vpc.id not in [a.vpc_id for a in gate.attachments]:
                conn.attach_internet_gateway(gate.id, vpc.id)
        for rtab in rtabs(conn):
            if gate.id not in [r.gateway_id for r in rtab.routes]:
                conn.create_route(rtab.id, '0.0.0.0/0', gateway_id=gate.id)
    if not addrs(conn):
        conn.allocate_address(domain='vpc')
        while not addrs(conn):
            logging.info('Creating public IP address...')
            sleep(SLEEP)
    if not irsvs(conn):
        conn.run_instances(IMAGE, key_name=key_pairs(conn)[0].name,
            security_group_ids=[sgroups(conn)[0].id],
            subnet_id=subnets(conn)[0].id, instance_type=INSTANCE_TYPE
        ).instances[0].add_tag('Name', tag())
    while set(i.state for i in insts(conn)) != {'running'}:
        for inst in insts(conn):
            logging.info('Starting. Instance %s current state: %s' % (
                inst.id, inst.state))
            inst.start()
        sleep(SLEEP)
    for inst in insts(conn):
        for addr in addrs(conn):
            if addr.instance_id != inst.id:
                addr.associate(inst.id)
    conn.close()
    logging.info('Created.')

def delete():
    logging.info('Deleting.')
    conn = connect()
    while insts(conn):
        for inst in insts(conn):
            logging.info('Terminating. Instance %s current state: %s' % (
                inst.id, inst.state))
            inst.terminate()
        sleep(SLEEP)
    while addrs(conn):
        for addr in addrs(conn):
            logging.info('Releasing address %s' % addr.public_ip)
            if not addr.association_id:
                conn.release_address(allocation_id=addr.allocation_id)
        sleep(SLEEP)
    for gate in gates(conn):
        for vpc in vpcs(conn):
            conn.detach_internet_gateway(gate.id, vpc.id)
        conn.delete_internet_gateway(gate.id)
    for sgroup in sgroups(conn):
        conn.delete_security_group(group_id=sgroup.id)
    for key_pair in key_pairs(conn):
        conn.delete_key_pair(key_pair.name)
    for subnet in subnets(conn):
        conn.delete_subnet(subnet.id)
    for vpc in vpcs(conn):
        conn.delete_vpc(vpc.id)
    conn.close()
    logging.info('Deleted.')

if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option('-d', '--delete', dest='delete', action='store_true')
    parser.add_option('-r', '--run', dest='run', action='store_true')
    parser.add_option('-s', '--stop', dest='stop', action='store_true')
    parser.add_option('-l', '--log', dest='log', help='error|warn|info|debug')
    (options, args) = parser.parse_args()
    logging.basicConfig(format='%(levelname)-8s %(asctime)-15s %(message)s')
    if options.log:
        logging.getLogger().setLevel(getattr(logging, options.log.upper()))
    if options.delete:
        delete()
    elif options.run:
        create()
        conn = connect()
        while set(i.state for i in insts(conn)) != {'running'}:
            for inst in insts(conn):
                logging.info('Starting. Instance %s current state: %s' % (
                    inst.id, inst.state))
                inst.start()
            sleep(SLEEP)
        with open('/var/lib/%s/ip.txt' % APP, 'w') as f:
            f.write(str(insts(conn)[0].ip_address))
        conn.close()
        logging.info('Running.')
    elif options.stop:
        create()
        conn = connect()
        while set(i.state for i in insts(conn)) != {'stopped'}:
            for inst in insts(conn):
                logging.info('Stopping. Instance %s current state: %s' % (
                    inst.id, inst.state))
                inst.stop()
            sleep(SLEEP)
        conn.close()
        logging.info('Stopped.')
    else:
        logging.error('Nothing to do.')
    with open('/var/lib/%s/success' % APP, 'w') as f:
        pass
