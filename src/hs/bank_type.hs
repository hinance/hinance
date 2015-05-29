-- Copyright 2015 Oleg Plakhotniuk
--
-- This file is part of Hinance.
--
-- Hinance is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Hinance is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Hinance.  If not, see <http://www.gnu.org/licenses/>.

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
