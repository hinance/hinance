from weboob.tools.application.base import Application
from weboob.capabilities.bank import CapBank
from weboob.capabilities.shop import CapShop
import json
from time import time
from sys import stdout

class MyApp(Application):

  REPORT_TIME = 10
  VERSION = '0'
  APPNAME = 'hinance-worker'

  def add_application_options(self, group):
    group.add_option('-o', '--output-file', help='where to write output')

  def main(self, argv):
    banks = []
    shops = []
    for backend in self.load_backends().values():
      if backend.has_caps(CapBank):
        banks.append(self.get_bank_data(backend))
      if backend.has_caps(CapShop):
        shops.append(self.get_shop_data(backend))
    result = json.dumps({'banks': banks, 'shops': shops},
                        indent=2, sort_keys=True)
    with open(self.options.output_file, 'w') as f:
      f.write(result)

  def get_bank_data(self, backend):
    lastReport = time()
    accounts = []
    for a in backend.iter_accounts():
      transactions = []
      for t in backend.iter_history(a):
        transactions.append({
          u'date': unicode(t.date),
          u'rdate': unicode(t.rdate),
          u'label': unicode(t.label),
          u'amount': unicode(t.amount)})
        if time()-lastReport > self.REPORT_TIME:
          print u'Scraped %i transactions in account %s' % \
            (len(transactions), a.id)
          stdout.flush()
          lastReport = time()
      print u'Scraped %i transactions in account %s' % \
        (len(transactions), a.id)
      stdout.flush()
      accounts.append({
        u'id': unicode(a.id),
        u'label': unicode(a.label),
        u'balance': unicode(a.balance),
        u'currency': unicode(a.currency),
        u'transactions': transactions})
    return accounts

  def get_shop_data(self, backend):
    lastReport = time()
    orders = []
    currency = backend.get_currency()
    for o in backend.iter_orders():
      payments = []
      for p in backend.iter_payments(o):
        payments.append({
          u'date': unicode(p.date),
          u'method': unicode(p.method),
          u'amount': unicode(p.amount)})
      shipments = []
      for s in backend.iter_shipments(o):
        items = []
        for i in backend.iter_items(s):
          items.append({
            u'label': unicode(i.label),
            u'url': unicode(i.url),
            u'price': unicode(i.price)})
        shipments.append({
          u'shipping': unicode(s.shipping),
          u'discount': unicode(s.discount),
          u'tax': unicode(s.tax),
          u'items': items})
      orders.append({
        u'id': unicode(o.id),
        u'date': unicode(o.date),
        u'payments': payments,
        u'shipments': shipments})
      if time()-lastReport > self.REPORT_TIME:
        print u'Scraped %i orders' % len(orders)
        stdout.flush()
        lastReport = time()
    print u'Scraped %i orders' % len(orders)
    stdout.flush()
    return {'currency': currency,
            'orders': orders}

if __name__ == '__main__':
  MyApp.run()
