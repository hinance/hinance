module Hinance.WebPages (webpages) where
import Data.Function
import Data.List
import Hinance.Bank.Type
import Hinance.Changes
import Hinance.User.Data
import Hinance.User.Type
import Text.Printf
import Text.Show.Pretty

webpages = 
 [("home.html", ["home page"]),
  ("diag.html", html diags)]

diags = [
  printf "<h3>Checks (%i)</h3>" (length checks),
  printf "<pre>%s</pre>" (ppShow checks),
  printf "<h3>Changes without groups (%i)</h3>" (length nchgs),
  printf "<pre>%s</pre>" (ppShow nchgs),
  printf "<h3>Unbalanced groups (%i)</h3>" (length ugrps),
  printf "<pre>%s</pre>" (ppShow ugrps),
  printf "<h3>Slices mismatch (%i)</h3>" (length mparts),
  printf "<pre>%s</pre>" (ppShow cparts)] where
    nchgs = filter (not.grouped) (chgsact++chgsplan)
    ugrps = unbalgrps $ filter grouped (chgsact++chgsplan)
    cparts = concatMap chkparts [chgsact, chgsplan]
    mparts = concatMap (\(_, (a,b)) -> a++b) cparts
    checks = concatMap (concatMap chkbalance.baccs) banks
    chkparts chgs = map (\s -> (sname s, chk$extract s)) slices where
      extract Slice{stags=wts, scategs=cts} = (wts, concatMap sctags cts)
      chk (wts, pts) = (srt $ whole \\ parts, srt $ parts \\ whole) where
        srt = reverse.(sortBy (compare `on` ctime))
        whole = sort $ filter (\Change{ctags=ts}->all (flip elem$ts) wts) chgs
        parts = sort $ concatMap part pts
        part pt = filter (\Change{ctags=ts}->elem pt ts) whole
    unbalgrps = filter (((/=) 0).sum.map camount) . groupSortBy cgroup
    chkbalance a | baldiff a /= 0 = [printf "Account %s balance mismatch: %i"
                                     (baid a) (baldiff a)]
                 | otherwise = [] :: [String]
    baldiff a = (-) (babalance a) $ foldl (+) 0 $ map btamount $ batrans a

html body = [
  "<!DOCTYPE html>",
  "<html lang=\"en\">",
  "  <head>",
  "    <meta charset=\"utf-8\">",
  "    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">",
  "    <meta name=\"viewport\" content=\"width=device-width, " ++ 
            "initial-scale=1\">",
  "    <title>Hinance</title>",
  "      <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com" ++
                                 "/bootstrap/3.3.1/css/bootstrap.min.css\">",
  "      <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com" ++
                           "/bootstrap/3.3.1/css/bootstrap-theme.min.css\">",
  "  </head>",
  "  <body>"] ++ (map (
  "    " ++) body) ++ [
  "    <script src=\"https://ajax.googleapis.com/ajax/libs" ++ 
                    "/jquery/1.11.1/jquery.min.js\"></script>",
  "    <script src=\"https://maxcdn.bootstrapcdn.com" ++
                    "/bootstrap/3.3.1/js/bootstrap.min.js\"></script>",
  "    <script type=\"text/javascript\" src=\"hinance.js\"></script>",
  "  </body>",
  "</html>"]
