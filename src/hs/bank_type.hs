module Hinance.Bank.Type where
import Hinance.Currency

data Bank = Bank {baccs::[BankAcc], bid::String} deriving (Read, Show)
data BankAcc = BankAcc {batrans::[BankTrans], balabel::String, baid::String,
  bacurrency::Currency, babalance::Integer, balimit::Integer,
  bapaytime::Integer, bapaymin::Integer} deriving (Read, Show)
data BankTrans = BankTrans {btamount::Integer, btlabel::String,
  bttime::Integer, btrtime::Integer} deriving (Read, Show)
