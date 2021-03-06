# Copyright 2015 Oleg Plakhotniuk
#
# This file is part of Hinance.
#
# Hinance is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Hinance is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hinance.  If not, see <http://www.gnu.org/licenses/>.

from weboob.tools.application.base import Application
from weboob.capabilities.base import Currency
from weboob.capabilities.bank import CapBank, Account
from weboob.capabilities.shop import CapShop
from datetime import datetime
from time import time
from sys import stdout
from numbers import Number

class MyApp(Application):

  REPORT_TIME = 10
  VERSION = '0'
  APPNAME = 'hinance'

  def main(self, argv):
    banks = []
    shops = []
    for backend in self.load_backends().values():
      print 'Scraping backend %s' % backend.name
      if backend.has_caps(CapBank):
        banks += [
          u'  ++ [' ] + [
          u'    %s' % s for s in self.get_bank_data(backend)] + [
          u'  ]']
      if backend.has_caps(CapShop):
        shops += [
          u'  ++ [' ] + [
          u'    %s' % s for s in self.get_shop_data(backend)] + [
          u'  ]']
    with open('banks.hs.part', 'w') as f:
      f.write(u'\n'.join(banks))
    with open('shops.hs.part', 'w') as f:
      f.write(u'\n'.join(shops))

  def get_bank_data(self, backend):
    lastReport = time()
    baccs = []
    for a in backend.iter_accounts():
      batrans = []
      for t in backend.iter_history(a):
        batrans.append([
          u'BankTrans',
          u'{ bttime = %i' % totime(t.date),
          u', btlabel = %s' % tostr(t.label),
          u', btamount = %i' % tocent(t.amount),
          u'}'])
        if time()-lastReport > self.REPORT_TIME:
          print u'Scraped %i transactions in account %s' % \
            (len(batrans), a.id)
          stdout.flush()
          lastReport = time()
      print u'Scraped %i transactions in account %s' % \
        (len(batrans), a.id)
      stdout.flush()
      maybeNum = lambda x: ('Just %i'%x) if isinstance(x,Number) else 'Nothing'
      baccs.append([
        u'BankAcc',
        u'{ baid = %s' % tostr(a.id),
        u', balabel = %s' % tostr(a.label),
        u', babalance = %i' % tocent(a.balance),
        u', bacurrency = %s' % a.currency,
        u', bacard = %s' % (a.type == Account.TYPE_CARD),
        u', balimit = %s' % maybeNum(tocent(a.cardlimit)),
        u', bapaymin = %s' % maybeNum(tocent(a.paymin)),
        u', bapaytime = %s' % maybeNum(totime(a.paydate)),
        u', batrans ='] + [
        u'  %s' % s for s in r_list(batrans)] + [
        u'}'])
    return [
      u'Bank',
      u'{ bid = %s' % tostr(backend.name),
      u', baccs ='] + [
      u'  %s' % s for s in r_list(baccs)] + [
      u'}']

  def get_shop_data(self, backend):
    lastReport = time()
    sorders = []
    currency = Currency.get_currency(backend.get_currency())
    for o in backend.iter_orders():
      sopayments = [[
        u'ShopPayment',
        u'{ sptime = %i' % totime(p.date),
        u', spamount = %i' % tocent(p.amount),
        u', spmethod = %s' % tostr(p.method),
        u'}'] for p in backend.iter_payments(o)]
      soitems = [[
        u'ShopItem',
        u'{ silabel = %s' % tostr(i.label),
        u', siprice = %i' % tocent(i.price),
        u', siurl = %s' % tostr(i.url),
        u'}'] for i in backend.iter_items(o)]
      sorders.append([
        u'ShopOrder',
        u'{ soid = %s' % tostr(o.id),
        u', sotime = %i' % totime(o.date),
        u', sodiscount = %i' % tocent(o.discount),
        u', soshipping = %i' % tocent(o.shipping),
        u', sotax = %i' % tocent(o.tax),
        u', sopayments ='] + [
        u'  %s' % s for s in r_list(sopayments)] + [
        u', soitems ='] + [
        u'  %s' % s for s in r_list(soitems)] + [
        u'}'])
      if time()-lastReport > self.REPORT_TIME:
        print u'Scraped %i orders' % len(sorders)
        stdout.flush()
        lastReport = time()
      payments_total = sum(p.amount for p in backend.iter_payments(o))
      items_total = sum(i.price for i in backend.iter_items(o))
      order_total = o.shipping + o.discount + o.tax
      assert payments_total == items_total + order_total, \
        u'%s != %s + %s' % (payments_total, items_total, order_total)
      assert list(backend.iter_items(o))
      assert list(backend.iter_payments(o))

    print u'Scraped %i orders' % len(sorders)
    stdout.flush()
    return [
      u'Shop',
      u'{ sid = %s' % tostr(backend.name),
      u', scurrency = %s' % currency,
      u', sorders ='] + [
      u'  %s' % s for s in r_list(sorders)] + [
      u'}']

def r_list(xss):
  return [
    u'['] + [
    u'  %s' % x for xs in xss for x in (xs + [','])][:-1] + [
    u']'
  ]

def tocent(d):
  try:
    return int(d*100)
  except TypeError:
    return None

def totime(dt):
  try:
    return int((dt - datetime(1970, 1, 1)).total_seconds())
  except TypeError:
    return None

def tostr(s):
  return u'"' + s.encode('unicode_escape') \
    .replace('"', '\\"').replace('\\u','\\x') + u'"'

if __name__ == '__main__':
  MyApp.run()
