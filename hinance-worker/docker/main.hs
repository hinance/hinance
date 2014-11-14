module Main where
import Hinance.Currency
import Hinance.Bank.Data
import Hinance.Bank.Type
import Hinance.Shop.Data
import Hinance.Shop.Type
import Hinance.Taggable
import Hinance.User.Tag
import Hinance.User.Taggable
import Text.Show.Pretty

main = do
  putStr $ ppShow $ concat $ (map changes $ banks) ++ (map changes $ shops)

tags x = filter (tagged x) [minBound::Tag ..]

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
