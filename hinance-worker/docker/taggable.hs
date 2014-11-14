module Hinance.Taggable where
import Hinance.User.Tag

class Taggable a where
  tagged :: a -> Tag -> Bool
