data Currency = USD | EUR | GBP deriving (Read, Show)

data Bank = Bank {baccs::[BankAcc], bid::String} deriving (Read, Show)
data BankAcc = BankAcc {batrans::[BankTrans], balabel::String, baid::String,
  bacurrency::Currency, babalance::Integer} deriving (Read, Show)
data BankTrans = BankTrans {btamount::Integer, btlabel::String,
  bttime::Integer, btrtime::Integer} deriving (Read, Show)

data Shop = Shop {sid::String, scurrency::Currency, sorders::[ShopOrder]}
  deriving (Read, Show)
data ShopOrder = ShopOrder {soid::String, sodiscount::Integer,
  sotime::Integer, soshipping::Integer, sotax::Integer, soitems::[ShopItem],
  sopayments::[ShopPayment]} deriving (Read, Show)
data ShopItem = ShopItem {silabel::String, siprice::Integer, siurl::String}
  deriving (Read, Show)
data ShopPayment = ShopPayment {spamount::Integer, sptime::Integer,
  spmethod::String} deriving (Read, Show)

shops = [
  ] ++ [
    Shop
    { sid="amazonj"
    , scurrency=USD
    , sorders=
      [ ShopOrder
        { soid="109-9013259-5313812"
        , sodiscount=0, 
          sotime=1234567890, 
          soshipping=0,
          sotax=393,
          soitems=
          [
            ShopItem
            {
              silabel="Whitmor 6021-181 Ebony Chrome Add-On Skirt/Slack Hanger, Set of 3", 
              siprice=699, 
              siurl="http://www.amazon.com/gp/product/B000L1F2GU/ref=ox_ya_os_product_refresh_T1"
            },
            ShopItem
            {
              silabel="Adagio Teas PersonaliTea Ceramic Teapot with Infuser Basket, 24-Ounce, Plum", 
              siprice=604, 
              siurl="http://www.amazon.com/gp/product/B00EOJQMJG/ref=ox_ya_os_product_refresh_T1"
            }
          ],
          sopayments=
          [
            ShopPayment
            {
              spamount=1081, 
              sptime=1234567890,
              spmethod="AMAZON.COM STORE CARD 0097"
            }, 
            ShopPayment
            {
              spamount=4077, 
              sptime=1234567890,
              spmethod="AMAZON.COM STORE CARD 0097"
            }
          ]
        }
      ]
    }
  ]

