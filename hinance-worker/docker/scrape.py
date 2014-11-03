from weboob.core import Weboob
from weboob.capabilities.bank import CapBank
from sys import argv
import logging
import json

def scrape():
    w = Weboob()
    backends = {}
    for bname, b in w.load_backends(CapBank).items():
        accounts = []
        for a in b.iter_accounts():
            transactions = []
            for t in b.iter_history(a):
                transactions.append({
                    u'date': unicode(t.date),
                    u'rdate': unicode(t.rdate),
                    u'label': unicode(t.label),
                    u'amount': unicode(t.amount)})
            accounts.append({
                u'id': unicode(a.id),
                u'label': unicode(a.label),
                u'balance': unicode(a.balance),
                u'currency': unicode(a.currency),
                u'transactions': transactions})
        backends[bname] = accounts
    return backends

logging.basicConfig(format='%(levelname)-8s %(asctime)-15s %(message)s')
logging.getLogger().setLevel(logging.DEBUG)

if __name__ == '__main__':
    with open(argv[1], 'w') as f:
        f.write(json.dumps(scrape(), indent=2, sort_keys=True))
