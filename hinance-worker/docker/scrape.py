from weboob.tools.application.base import Application
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
    lastReport = time()
    accounts = []
    for backend in self.load_backends().values():
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
    result = json.dumps(accounts, indent=2, sort_keys=True)
    with open(self.options.output_file, 'w') as f:
      f.write(result)

if __name__ == '__main__':
  MyApp.run()
