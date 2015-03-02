module Hinance.User.Type where
import Hinance.User.Tag
import Hinance.Currency

class Taggable a where
  tagged :: a -> Tag -> Bool

class Patchable a where
  patched :: [a] -> [a]

data Change = Change {camount::Integer, ctime::Integer, clabel::String,
  ccur::Currency, curl::String, cgroup::String, ctags::[Tag]}
  deriving (Read, Show, Ord, Eq)

data Slice = Slice {sname::String, scategs::[SliceCateg], stags::[Tag]}
  deriving (Read, Show, Ord, Eq)

data SliceCateg = SliceCateg {scbg::String, scfg::String,
                              scname::String, sctags::[Tag]}
  deriving (Read, Show, Ord, Eq)
