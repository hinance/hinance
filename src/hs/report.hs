module Hinance.Diag (diagcount, diagslices, diagslicesflat, diagnogrp,
                     diagugrps, diagchecks) where
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

diffslices chgs = map (\s -> (sname s, diff$extract s)) slices where
  extract Slice{stags=wts, scategs=cts} = (wts, concatMap sctags cts)
  diff (wts, pts) = (srt $ whole \\ parts, srt $ parts \\ whole) where
    srt = reverse.(sortBy (compare `on` ctime))
    whole = sort $ filter (\Change{ctags=ts}->all (flip elem$ts) wts) chgs
    parts = sort $ concatMap part pts
    part pt = filter (\Change{ctags=ts}->elem pt ts) whole
