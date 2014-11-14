import HinanceTypes
import HinanceBanks
import Text.Regex.Posix

data Change = Change {camount::Integer, ctime::Integer, clabel::String,
  curl::String, ctags::[Tag]} deriving (Read, Show)

data Tag = TagWalmart | TagDallas | TagPlano | TagParking | TagSprouts
  deriving (Read, Show, Enum, Bounded)

class Taggable a where
  tagged :: Tag -> a -> Bool
  tags :: a -> [Tag]

instance Taggable (Bank, BankAcc, BankTrans) where
  tagged TagWalmart (_, _, BankTrans {btlabel=s}) = s =~ "WAL-MART"
  tagged TagParking (_, _, BankTrans {btlabel=s}) = s =~ "PARKING"
  tagged TagPlano (_, _, BankTrans {btlabel=s}) = s =~ "PLANO"
  tagged TagDallas (_, _, BankTrans {btlabel=s}) = s =~ "DALLAS"
  tagged _ _ = False
  tags (_, _, _) = []

testbank = banks !! 0
testacc = baccs testbank !! 0
testtrans = batrans testacc !! 0
testtrans2 = batrans testacc !! 1

test = do
  putStrLn $ show $ tagged TagParking (testbank, testacc, testtrans)
  putStrLn $ show $ tagged TagParking (testbank, testacc, testtrans2)
  putStrLn $ show $ tagged TagSprouts (testbank, testacc, testtrans2)
  putStrLn $ show $ tags (testbank, testacc, testtrans)
  putStrLn $ show $ tags (testbank, testacc, testtrans2)
