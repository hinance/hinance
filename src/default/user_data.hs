module Hinance.User.Data (
  addtagged, canmerge, canxfer, patched,
  planfrom, planto, planned, slices, tagged
) where
import Hinance.User.Tag
import Hinance.User.Type
import Hinance.Bank.Type
import Hinance.Shop.Type
import Hinance.Currency

blue = "#337AB7"
cyan = "#5BC0DE"
green = "#5CB85C"
grey = "#777"
red = "#D9534F"
white = "#FFF"
yellow = "#F0AD4E"

addtagged _ = [] :: [Tag]
canxfer _ _ = False
canmerge _ _ = False

slices = [
  Slice {sname="Expenses", stags=[TagExpense], scategs=[
    SliceCateg {scname="Tax", scbg=green, scfg=white,
      sctags=[TagTax]},
    SliceCateg {scname="Shipping", scbg=blue, scfg=white,
      sctags=[TagShipping]},
    SliceCateg {scname="Other", scbg=red, scfg=white,
      sctags=[TagOther]}]},

  Slice {sname="Income", stags=[TagIncome], scategs=[
    SliceCateg {scname="Discounts", scbg=blue,scfg=white,sctags=[TagDiscount]},
    SliceCateg {scname="Other", scbg=red, scfg=white, sctags=[TagOther]}]},

  Slice {sname="Assets", stags=[TagAsset], scategs=[
    SliceCateg {scname="Other", scbg=red, scfg=white,
      sctags=[TagOther]}]},

  Slice {sname="All", stags=[], scategs=[
    SliceCateg {scname="Assets", scbg=green, scfg=white, sctags=[TagAsset]},
    SliceCateg {scname="Income", scbg=blue, scfg=white, sctags=[TagIncome]},
    SliceCateg {scname="Expenses",scbg=red,scfg=white,sctags=[TagExpense]}]}]

instance Taggable (Bank, BankAcc, BankTrans) where
  tagged _ t
    | t==TagAsset = True
    | t==TagOther = True
    | otherwise = False

instance Taggable (Shop, ShopOrder, String) where
  tagged (_, _, l) t
    | t==TagExpense  = l=="shipping" || l=="tax"
    | t==TagIncome   = l=="discount"
    | t==TagDiscount = l=="discount"
    | t==TagShipping = l=="shipping"
    | t==TagTax      = l=="tax"
    | otherwise      = False

instance Taggable (Shop, ShopOrder, ShopPayment) where
  tagged _ t
    | t==TagAsset = True
    | t==TagOther = True
    | otherwise = False

instance Taggable (Shop, ShopOrder, ShopItem) where
  tagged _ t
    | t==TagExpense = True
    | t==TagOther = True
    | otherwise = False

instance Patchable Shop where
  patched = id

instance Patchable Bank where
  patched = id

planfrom = 0
planto = 0
planned = []
