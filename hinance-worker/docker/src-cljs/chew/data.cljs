(ns chew.data (:require chew.type))

(def diag [
  (chew.type/Diag. "Checks" 1 [
    "[ \"Account 0097 balance mismatch: 4112\" ]"])
  (chew.type/Diag. "Changes without groups" 6 [
    "[ Change"
    "    { camount = 11561"
    "    , ctime = 1420588800"
    "    , clabel = \"ONLINE PYMT-THANK YOU ATLANTA GA\""
    "    , ccur = USD"
    "    , curl = \"\""
    "    , cgroup = \"\""
    "    , ctags = [ TagAsset , TagAmazon0097 , TagAmazonCard , TagPayment ]"
    "    }"
    "]"])
  (chew.type/Diag. "Unbalanced groups" 1 [
    "[ [ Change"
    "      { camount = 11561"
    "      , ctime = 1420588800"
    "      , clabel = \"ONLINE PYMT-THANK YOU ATLANTA GA\""
    "      , ccur = USD"
    "      , curl = \"\""
    "      , cgroup = \"\""
    "      , ctags = [ TagAsset , TagAmazon0097 , TagAmazonCard , TagPayment ]"
    "      }"
    "  ]"
    "]"])
  (chew.type/Diag. "Partitions mismatch" 1 [
    "[ ( [ Change"
    "        { camount = 204"
    "        , ctime = 1420416000"
    "        , clabel = \"101 Things I Learned in Fashion School\""
    "        , ccur = USD"
    "        , curl = \"https://www.amazon.com/gp/product/0446550299\""
    "        , cgroup = \"amazonj 108-2939534-9805813\""
    "        , ctags = [ TagExpense , TagAmazon ]"
    "        }"
    "    ]"
    "  , []"
    "  )"
    ", ( [] , [] )"
    ", ( [] , [] )"
    ", ( [] , [] )"
    "]"])
])
