-- Copyright 2015 Oleg Plakhotniuk
--
-- This file is part of Hinance.
--
-- Hinance is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Hinance is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Hinance.  If not, see <http://www.gnu.org/licenses/>.

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
