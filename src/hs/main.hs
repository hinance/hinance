module Main where
import Data.List
import Hinance.WebPages
import System.Environment

main = do
  args <- getArgs
  mapM (\(n,d) -> writeFile n d) $ webpages $ args !! 0
