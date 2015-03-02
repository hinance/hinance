module Main where
import Data.List
import Hinance.WebPages

main = do mapM (\(n,d) -> writeFile n $ concat $ intersperse "\n" d) webpages
