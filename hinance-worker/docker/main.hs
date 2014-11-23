module Main where
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

main = do
  putStrLn.ppShow.concat.map (concat.map chkbalance.baccs).patched$banks
  putStrLn.ppShow.concat $ (map changes.patched$banks) ++
                           (map changes.patched$shops)

tags x = filter (tagged x) [minBound::Tag ..]
baldiff a = (-) (babalance a) $ foldl (+) 0 $ map btamount $ batrans a
chkbalance a | baldiff a /= 0 = [printf "Account %s balance mismatch: %i"
                                 (baid a) (baldiff a)]
             | otherwise = [] :: [String]

data Change = Change {camount::Integer, ctime::Integer, clabel::String,
  ccur::Currency, curl::String, cgroup::String, ctags::[Tag]}
  deriving (Read, Show)

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
                 ccur=scurrency s, cgroup=g' o, ctags=tags (s,o) }
      | (l,a) <- [("discount", sodiscount o),
                  ("shipping", soshipping o),
                  ("tax", sotax o)]]
    ++[ Change { camount=spamount p, ctime=sptime p, curl="", ccur=scurrency s,
                 clabel=spmethod p, cgroup=g' o, ctags=tags (s,o,p) }
      | p <- sopayments o]
    ++[ Change { camount=siprice i, ctime=sotime o, curl=siurl i, cgroup=g' o,
                 ccur=scurrency s, clabel=silabel i, ctags=tags (s,o,i) }
      | i <- soitems o]
    | o <- sorders s]
    where g' o = (sid s) ++ " " ++ (soid o)
