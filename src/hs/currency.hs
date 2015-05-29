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

module Hinance.Currency where
import Text.Printf
import Text.Show.Pretty

data Currency = USD | EUR | GBP deriving (Read, Show, Ord, Eq)

fmtamount amount cur
  | cur == USD = "$" ++ famount
  | otherwise = famount ++ " " ++ (show cur) where
  famount = printf "%i.%02i" (quot amount 100) (abs $ rem amount 100)
