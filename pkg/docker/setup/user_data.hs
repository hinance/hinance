module Hinance.User.Data where
import Hinance.User.Tag
import Hinance.User.Type
import Hinance.Bank.Type
import Hinance.Shop.Type

addtagged _ = [] :: [Tag]
canxfer _ _ = False
canmerge _ _ = False
tagparts = []

instance Taggable (Bank, BankAcc, BankTrans) where
  tagged _ _ = True

instance Taggable (Shop, ShopOrder, String) where
  tagged _ _ = False

instance Taggable (Shop, ShopOrder, ShopPayment) where
  tagged _ _ = False

instance Taggable (Shop, ShopOrder, ShopItem) where
  tagged _ _ = False

instance Patchable Shop where
  patched = id

instance Patchable Bank where
  patched = id
