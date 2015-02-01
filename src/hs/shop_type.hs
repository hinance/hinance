module Hinance.Shop.Type where
import Hinance.Currency

data Shop = Shop {sid::String, scurrency::Currency, sorders::[ShopOrder]}
  deriving (Read, Show)
data ShopOrder = ShopOrder {soid::String, sodiscount::Integer,
  sotime::Integer, soshipping::Integer, sotax::Integer, soitems::[ShopItem],
  sopayments::[ShopPayment]} deriving (Read, Show)
data ShopItem = ShopItem {silabel::String, siprice::Integer, siurl::String}
  deriving (Read, Show)
data ShopPayment = ShopPayment {spamount::Integer, sptime::Integer,
  spmethod::String} deriving (Read, Show)
