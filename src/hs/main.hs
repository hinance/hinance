module Main where
import Data.Char
import Data.Function
import Data.List
import Data.Monoid
import Hinance.Currency
import Hinance.Bank.Data
import Hinance.Bank.Type
import Hinance.Shop.Data
import Hinance.Shop.Type
import Hinance.User.Tag
import Hinance.User.Type
import Hinance.User.Data
import Text.Show.Pretty
import Text.Printf

main = do putStrLn.concat $ intersperse "\n" $ concat $ xs where
  xs = [[""],diagscljs,
        [""],chgscljs chgsact "chgsact",
        [""],chgscljs chgsplan "chgsplan"]

diagscljs = concat [["(def diag ["],
  (cljs "Checks" (length checks) checks),
  (cljs "Changes without groups" (length nchgs) nchgs),
  (cljs "Unbalanced groups" (length ugrps) ugrps),
  (cljs "Partitions mismatch" (length mparts) cparts),
  ["])"]] where
    nchgs = filter (not.grouped) (chgsact++chgsplan)
    ugrps = unbalgrps $ filter grouped (chgsact++chgsplan)
    cparts = concatMap chkparts [chgsact, chgsplan]
    mparts = concatMap (\(a,b) -> a++b) cparts
    checks = concatMap (concatMap chkbalance.baccs) banks
    cljs s n xs = [printf "  (hinance.type/Diag. \"%s\" %i [" s n] ++
                   (map ((printf "    %s").show) (lines $ ppShow xs)) ++
                   ["  ])"]

chgscljs chgs title = concat [[printf "(def %s [" title],
  (concatMap cljs chgs),["])"]] where
  cljs c = [printf "  (hinance.type/Change. %s %i :%s"
             (numcljs $ camount c) (ctime c) (show $ ccur c),
            "    " ++ (show $ filter isAscii $ clabel c),
            "    " ++ (show $ filter isAscii $ cgroup c),
            (printf "    #{%s}" $ concat $ intersperse " " $
              [printf ":%s" $ show t | t <- ctags c]),
            printf "    %s)" (show $ curl c)]

numcljs n
  | n >= 0 = show n
  | otherwise = printf "(- %s)" (show$abs n)

chgsact = (sortBy (compare`on`ctime)).(concatMap addchanges)
            .joinxfers.mergechgs$raw where
  raw = concat $ (map changes banks) ++ (map changes shops)

chgsplan=(sortBy (compare`on`ctime)) . (++ ps) . concat
  . (filter$(< planfrom).ctime.head) . (groupSortBy cgroup) $ chgsact where
  ps = takeWhile ((<= planto).ctime) $ dropWhile ((>= planfrom).ctime) planned

banks = patched $ map (mrgbacs.mrgbs) $ groupSortBy bid banksraw where
  mrgbs = foldl1 (\a x -> x{baccs = (baccs a) ++ (baccs x)})
  mrgbacs b = b{baccs = map mrgacs $ groupSortBy baid $ baccs b}
  mrgacs acs = newest{batrans = merge $ map batrans acs} where
    newest = maximumBy (on compare (bttime.head.batrans)) acs

shops = patched $ map mrgss $ groupSortBy sid $ shopsraw where
  mrgss (s:ss) = s{sorders = merge $ map sorders (s:ss)}

tags x = filter (tagged x) [minBound::Tag ..]
grouped = (/="").cgroup
groupSortBy f = (groupBy $ on (==) f) . (sortBy $ on compare f)
splits xs = [splitAt i xs | i <- [0..length xs]]
baldiff a = (-) (babalance a) $ foldl (+) 0 $ map btamount $ batrans a

chkbalance a | baldiff a /= 0 = [printf "Account %s balance mismatch: %i"
                                 (baid a) (baldiff a)]
             | otherwise = [] :: [String]

chkparts chgs = map chk tagparts where
  chk (wf, pfs) = (srt $ whole \\ parts, srt $ parts \\ whole) where
    srt = reverse.(sortBy (compare `on` ctime))
    whole = sort $ filter (\Change{ctags=ts} -> wf ts) chgs
    parts = sort $ concatMap part pfs
    part pf = filter (\Change{ctags=ts}->pf ts) whole

unbalgrps = filter (((/=) 0).sum.map camount) . groupSortBy cgroup

mchgsplits as bs can = sortBy cmp splits where
  cmp = (on compare) (uncurry$(.)(.)(.)abs$on(-)ctime) `on` fst
  splits = [((a,b), (as',bs'))
           | (a,as')<-splits' [] as, (b,bs')<-splits' [] bs, can a b]
  splits' _ [] = []
  splits' hs (x:ts) = (x, hs ++ ts) : splits' (x:hs) ts

joinxfers = joinxfers'.partition grouped where
  joinxfers' (gcs,ngcs) = gcs++(concatMap xfers$groupSortBy crit$ngcs)
  crit x = (ccur x, abs $ camount x)
  xfers = xfers1.partition ((<=0).camount)
  xfers1 (as, bs) | null mchg = as ++ bs
                  | otherwise = uncurry xfers2 $ head mchg where
    can a b = any (uncurry $ on canxfer ctags) $ [(a,b), (b,a)]
    mchg = mchgsplits as bs can
    xfers2 (a,b) = (++) [c' a, c' b] . xfers1 where
      c' c = c{cgroup=printf "%i %i %i %i %s %s" (ctime a)
               (ctime b) (camount a) (camount b) (clabel a) (clabel b)}

mergechgs = concatMap mrg . groupSortBy (\x -> (ccur x, camount x)) where
  mrg = mrg1.partition grouped
  mrg1 (gs, ngs) | null mchg = gs ++ ngs
                 | otherwise = uncurry mrg2 $ head mchg where
    mchg = mchgsplits gs ngs (canmerge`on`ctags)
    mrg2 (g,ng) = (:) c' . mrg1 where
      c' = g {clabel = printf "%s %s" (clabel ng) (clabel g),
              ctags = union (ctags ng) (ctags g)}

addchanges c@Change{cgroup=g, ctags=ts}
  | g==""&&addtagged ts/=[] = [c', c'{camount=(-camount c),ctags=addtagged ts}]
  | otherwise = [c] where
  c' = c{cgroup=printf "%i %i %s" (ctime c) (camount c) (clabel c)}

class Mergeable a where
  mtime :: a -> Integer
  meq :: a -> a -> Bool
  merge :: [[a]] -> [a]
  merge = foldl1 merge2 . reverse . sortBy cmp where
    cmp x y = mconcat $ map (\fn -> (on compare (mtime.fn)) x y) [last, head]
    merge2 xs1 xs2 = head merges where
      merges = [h1++t1++t2 | (h1,t1)<-splits xs1, (h2,t2)<-reverse$splits xs2,
                length h2 >= length t1, all (uncurry meq)$on zip reverse h2 t1]

instance Mergeable BankTrans where
  mtime = bttime
  meq t1 t2 = bttime t1 == bttime t2 && btamount t1 == btamount t2

instance Mergeable ShopOrder where
  mtime = sotime
  meq = (==) `on` soid

class Changeable a where
  changes :: a -> [Change]

instance Changeable Bank where
  changes b =
    [ Change { camount=btamount t, ctime=bttime t, cgroup="", clabel=btlabel t,
               ccur=bacurrency a, curl="", ctags=tags (b,a,t) }
    | a <- baccs b, t <- batrans a]

instance Changeable Shop where
  changes s = concat
    [ [ Change { camount=a, ctime=sotime o, curl="", clabel=l,
                 ccur=scurrency s, cgroup=g' o, ctags=tags (s,o,l) }
      | (l,a) <- [("discount", sodiscount o),
                  ("shipping", soshipping o),
                  ("tax", sotax o)], a /= 0]
    ++[ Change { camount= -spamount p, ctime=sptime p, ccur=scurrency s,
                 clabel=spmethod p, curl="", cgroup=g' o, ctags=tags (s,o,p) }
      | p <- sopayments o]
    ++[ Change { camount=siprice i, ctime=sotime o, curl=siurl i, cgroup=g' o,
                 ccur=scurrency s, clabel=silabel i, ctags=tags (s,o,i) }
      | i <- soitems o]
    | o <- sorders s]
    where g' o = (sid s) ++ " " ++ (soid o)
