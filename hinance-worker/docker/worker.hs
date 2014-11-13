data Currency = USD | EUR deriving (Read, Show)
data BankTrans = BankTrans {btamount::Integer, btlabel::String,
  bttime::Integer, btrtime::Integer} deriving (Read, Show)
data BankAcc = BankAcc {batrans::[BankTrans], balabel::String, baid::String,
  bacurrency::Currency, babalance::Integer} deriving (Read, Show)
data Bank = Bank {baccs::[BankAcc], bid::String} deriving (Read, Show)

data ShopItem = ShopItem {silabel::String, siprice::Integer, siurl::String}
  deriving (Read, Show)
data ShopPayment = ShopPayment {spamount::Integer, sptime::Integer,
  spmethod::String} deriving (Read, Show)
data ShopOrder = ShopOrder {soid::String, sodiscount::Integer,
  sotime::Integer, soshipping::Integer, sotax::Integer, soitems::[ShopItem],
  sopayments::[ShopPayment]} deriving (Read, Show)
data Shop = Shop {scurrency::Currency, sorders::[ShopOrder]}
  deriving (Read, Show)
