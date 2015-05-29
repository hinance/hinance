module Hinance.User.Tag where
data Tag = TagAsset | TagExpense | TagIncome
  | TagDiscount | TagShipping | TagTax | TagOther
  deriving (Read, Show, Enum, Bounded, Eq, Ord)
