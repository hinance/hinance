from weboob.core import Weboob
from weboob.capabilities.bank import CapBank
from sys import argv
import logging
import json

def scrape(bname):
    backend = Weboob().load_backends(CapBank)[bname]
    accounts = []
    for a in backend.iter_accounts():
        transactions = []
        for t in backend.iter_history(a):
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
    return accounts

logging.basicConfig(format='%(levelname)-8s %(asctime)-15s %(message)s')
logging.getLogger().setLevel(logging.DEBUG)

if __name__ == '__main__':
    backend = argv[1]
    output = argv[2]
    result = json.dumps(scrape(backend), indent=2, sort_keys=True)
    with open(output, 'w') as f:
        f.write(result)
