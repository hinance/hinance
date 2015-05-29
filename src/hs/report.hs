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

module Hinance.Report where
import Data.Function
import Data.List
import Hinance.Bank.Type
import Hinance.Changes
import Hinance.User.Data
import Hinance.User.Type
import Text.Printf

diagcount = (length diagchecks) + (length diagnogrp) + (length diagugrps) +
            (length diagslicesflat)

diagslices = concatMap diffslices [chgsact, chgsplan]

diagslicesflat = concatMap (\(_, (a,b)) -> a++b) diagslices

diagnogrp = filter (not.grouped) (chgsact++chgsplan)

diagugrps = unbalgrps $ filter grouped (chgsact++chgsplan) where
  unbalgrps = filter (((/=) 0).sum.map camount) . groupSortBy cgroup

diagchecks = concatMap (concatMap chkbalance.baccs) banks where
  chkbalance a | baldiff a /= 0 = [printf "Account %s balance mismatch: %i"
                                   (baid a) (baldiff a)]
               | otherwise = [] :: [String]
  baldiff a = (-) (babalance a) $ foldl (+) 0 $ map btamount $ batrans a

diffslices chgs = map (\s -> (sname s, diff s)) slices where
  diff slice = (srt $ whole \\ parts, srt $ parts \\ whole) where
    srt = reverse.(sortBy (compare `on` ctime))
    whole = sort $ slicechgs slice chgs
    parts = sort $ concatMap part $ concatMap sctags $ scategs slice
    part pt = filter (\Change{ctags=ts}->elem pt ts) whole

catchgs c = filter (\Change{ctags=ts}->any (flip elem$ts) $ sctags c)

slicechgs s = filter (\Change{ctags=ts}->all (flip elem$ts) $ stags s)
