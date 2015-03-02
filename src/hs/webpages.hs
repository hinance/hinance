module Hinance.WebPages (webpages) where
import Data.Function
import Data.List
import Hinance.Bank.Type
import Hinance.Changes
import Hinance.User.Data
import Hinance.User.Type
import Text.Printf
import Text.Show.Pretty

webpages = 
 [("home.html", ["home page"]),
  ("diag.html", diagscljs)]

diagscljs = concat [["(def diag ["],
  (cljs "Checks" (length checks) checks),
  (cljs "Changes without groups" (length nchgs) nchgs),
  (cljs "Unbalanced groups" (length ugrps) ugrps),
  (cljs "Partitions mismatch" (length mparts) cparts),
  ["])"]] where
    nchgs = filter (not.grouped) (chgsact++chgsplan)
    ugrps = unbalgrps $ filter grouped (chgsact++chgsplan)
    cparts = concatMap chkparts [chgsact, chgsplan]
    mparts = concatMap (\(_, (a,b)) -> a++b) cparts
    checks = concatMap (concatMap chkbalance.baccs) banks
    cljs s n xs = [printf "  (hinance.type/Diag. \"%s\" %i [" s n] ++
                   (map ((printf "    %s").show) (lines $ ppShow xs)) ++
                   ["  ])"]
    chkparts chgs = map (\s -> (sname s, chk$extract s)) slices where
      extract Slice{stags=wts, scategs=cts} = (wts, concatMap sctags cts)
      chk (wts, pts) = (srt $ whole \\ parts, srt $ parts \\ whole) where
        srt = reverse.(sortBy (compare `on` ctime))
        whole = sort $ filter (\Change{ctags=ts}->all (flip elem$ts) wts) chgs
        parts = sort $ concatMap part pts
        part pt = filter (\Change{ctags=ts}->elem pt ts) whole
    unbalgrps = filter (((/=) 0).sum.map camount) . groupSortBy cgroup
    chkbalance a | baldiff a /= 0 = [printf "Account %s balance mismatch: %i"
                                     (baid a) (baldiff a)]
                 | otherwise = [] :: [String]
    baldiff a = (-) (babalance a) $ foldl (+) 0 $ map btamount $ batrans a
