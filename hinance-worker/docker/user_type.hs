module Hinance.User.Type where
import Hinance.User.Tag

class Taggable a where
  tagged :: a -> Tag -> Bool

class Patchable a where
  patched :: [a] -> [a]
