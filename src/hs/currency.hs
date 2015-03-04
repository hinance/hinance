module Hinance.Currency where
import Text.Printf
import Text.Show.Pretty

data Currency = USD | EUR | GBP deriving (Read, Show, Ord, Eq)

fmtamount amount cur
  | cur == USD = "$" ++ famount
  | otherwise = famount ++ " " ++ (show cur) where
  famount = printf "%i.%02i" (quot amount 100) (abs $ rem amount 100)
