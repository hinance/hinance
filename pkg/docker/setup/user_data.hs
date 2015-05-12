module Hinance.User.Data (
  addtagged, canmerge, canxfer, patched,
  planfrom, planto, planned, slices, tagged
) where
import Hinance.User.Tag
import Hinance.User.Type
import Hinance.Bank.Type
import Hinance.Shop.Type
import Hinance.Currency

addtagged _ = [] :: [Tag]
canxfer _ _ = False
canmerge _ _ = False
tagparts = []
slices = [] :: [Slice]

instance Taggable (Bank, BankAcc, BankTrans) where
  tagged _ _ = False

instance Taggable (Shop, ShopOrder, String) where
  tagged _ _ = False

instance Taggable (Shop, ShopOrder, ShopPayment) where
  tagged _ _ = False

instance Taggable (Shop, ShopOrder, ShopItem) where
  tagged _ _ = False

instance Patchable Shop where
  patched = id

instance Patchable Bank where
  patched banks = banks ++ [Bank {bid="", baccs=[
    BankAcc {baid="", balabel="", babalance=300, bacurrency=USD, 
             balimit=Nothing, bapaymin=Nothing, bapaytime=Nothing, batrans=[
      BankTrans {btlabel="", btamount=100, bttime=1},
      BankTrans {btlabel="", btamount=200, bttime=2}]}]}]

planfrom = 0
planto = 0
planned = []
