import json
from datetime import datetime
from decimal import Decimal

def r_bank(bank, bank_id):
  return [
    u'Bank',
    u'{ bid = %s' % tostr(bank_id),
    u', baccs ='] + [
    u'  %s' % s for s in r_list(map(r_acc, bank))] + [
    u'}'
  ]

def r_acc(acc):
  return [
    u'BankAcc',
    u'{ baid = %s' % tostr(acc['id']),
    u', balabel = %s' % tostr(acc['label']),
    u', babalance = %i' % tocent(acc['balance']),
    u', bacurrency = %s' % acc['currency'],
    u', batrans ='] + [
    u'  %s' % s for s in r_list(map(r_trans, acc['transactions']))] + [
    u'}'
  ]

def r_trans(trans):
  return [
    u'BankTrans',
    u'{ bttime = %i' % totime(trans['date']),
    u', btrtime = %i' % totime(trans['rdate']),
    u', btlabel = %s' % tostr(trans['label']),
    u', btamount = %i' % tocent(trans['amount']),
    u'}'
  ]

def r_shop(shop, shop_id):
  return [
    u'Shop',
    u'{ sid = %s' % tostr(shop_id),
    u', scurrency = %s' % shop['currency'],
    u', sorders ='] + [
    u'  %s' % s for s in r_list(map(r_order, shop['orders']))] + [
    u'}'
  ]

def r_order(order):
  return [
    u'ShopOrder',
    u'{ soid = %s' % tostr(order['id']),
    u', sotime = %i' % totime(order['date']),
    u', sodiscount = %i' % tocent(order['discount']),
    u', soshipping = %i' % tocent(order['shipping']),
    u', sotax = %i' % tocent(order['tax']),
    u', sopayments ='] + [
    u'  %s' % s for s in r_list(map(r_payment, order['payments']))] + [
    u', soitems ='] + [
    u'  %s' % s for s in r_list(map(r_item, order['items']))] + [
    u'}'
  ]

def r_payment(pmt):
  return [
    u'ShopPayment',
    u'{ sptime = %i' % totime(pmt['date']),
    u', spamount = %i' % tocent(pmt['amount']),
    u', spmethod = %s' % tostr(pmt['method']),
    u'}'
  ]

def r_item(item):
  return [
    u'ShopItem',
    u'{ silabel = %s' % tostr(item['label']),
    u', siprice = %i' % tocent(item['price']),
    u', siurl = %s' % tostr(item['url']),
    u'}'
  ]

def r_list(xss):
  return [
    u'['] + [
    u'  %s' % x for xs in xss for x in (xs + [','])][:-1] + [
    u']'
  ]

def tocent(s):
  return int(Decimal(s)*100)

def totime(s):
  dt = datetime.strptime(s, '%Y-%m-%d %H:%M:%S')
  return int((dt - datetime(1970, 1, 1)).total_seconds())

def tostr(s):
  return u'"' + s.encode('unicode_escape') \
    .replace('"', '\\"').replace('\\u','\\x') + u'"'

shops = [
  u'module HinanceShops where',
  u'import HinanceTypes',
  u'shops = []']
banks = [
  u'module HinanceBanks where',
  u'import HinanceTypes',
  u'banks = []']

for fname in ['amazonj', 'wellsfargoj', 'citibankj']:
  with open('/home/user/hinance-controller/%s.json' % fname) as f:
    data = json.loads(f.read())
    for shop in data['shops']:
      shops += [
        u'  ++ [' ] + [
        u'    %s' % s for s in r_shop(shop, fname)] + [
        u'  ]'
      ]
    for bank in data['banks']:
      banks += [
        u'  ++ [' ] + [
        u'    %s' % s for s in r_bank(bank, fname)] + [
        u'  ]'
      ]

with open('/srv/pub/projects/hinance/shops.hs', 'w') as f:
    f.write(u'\n'.join(shops))
with open('/srv/pub/projects/hinance/banks.hs', 'w') as f:
    f.write(u'\n'.join(banks))
