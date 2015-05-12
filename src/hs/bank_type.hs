module Hinance.Bank.Type where
import Hinance.Currency
import Data.Maybe

data Bank = Bank {baccs::[BankAcc], bid::String} deriving (Read, Show)
data BankAcc = BankAcc {batrans::[BankTrans], balabel::String, baid::String,
  bacurrency::Currency, babalance::Integer, balimit::(Maybe Integer),
  bapaymin::(Maybe Integer), bapaytime::(Maybe Integer),
  bacard::Bool} deriving (Read, Show)
data BankTrans = BankTrans {btamount::Integer, btlabel::String,
  bttime::Integer} deriving (Read, Show)
