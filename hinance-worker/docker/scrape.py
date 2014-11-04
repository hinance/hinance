from weboob.core import Weboob
from weboob.capabilities.bank import CapBank
from sys import argv
import logging
import json
from time import time

REPORT_TIME = 10

def scrape(bname):
    lastReport = time()
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
            if time()-lastReport > REPORT_TIME:
                logging.info(u'Scraped %i transactions in account %s' % \
                    (len(transactions), a.id))
                lastReport = time()
        logging.info(u'Scraped %i transactions in account %s' % \
            (len(transactions), a.id))
        accounts.append({
            u'id': unicode(a.id),
            u'label': unicode(a.label),
            u'balance': unicode(a.balance),
            u'currency': unicode(a.currency),
            u'transactions': transactions})
    return accounts

logging.basicConfig(format='%(levelname)-8s %(asctime)-15s %(message)s')
logging.getLogger().setLevel(logging.INFO)

if __name__ == '__main__':
    backend = argv[1]
    output = argv[2]
    result = json.dumps(scrape(backend), indent=2, sort_keys=True)
    with open(output, 'w') as f:
        f.write(result)
