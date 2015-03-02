module Hinance.WebPages (webpages) where
import Data.Function
import Data.List
import Hinance.Bank.Type
import Hinance.Changes
import Hinance.User.Data
import Hinance.User.Type
import Text.Printf
import Text.Show.Pretty

webpages = map (\(k,v) -> (k, html $ page v "TODO")) $
 [("home.html", home), ("diag.html", diag)] ++
 [(printf "slice%i.html" n, slice s) | (n, s) <- nslices]

nslices = zip [0..] slices :: [(Integer, Slice)]

home = "<h1>Welcome!</h1>"

slice s = "<h1>Slice " ++ (sname s) ++ "</h1>"

diag =
  (printf "<h3>Checks (%i):</h3>" (length checks)) ++
  (printf "<pre>%s</pre>" (ppShow checks)) ++
  (printf "<h3>Changes without groups (%i):</h3>" (length nchgs)) ++
  (printf "<pre>%s</pre>" (ppShow nchgs)) ++
  (printf "<h3>Unbalanced groups (%i):</h3>" (length ugrps)) ++
  (printf "<pre>%s</pre>" (ppShow ugrps)) ++
  (printf "<h3>Slices mismatch (%i):</h3>" (length mparts)) ++
  (printf "<pre>%s</pre>" (ppShow cparts)) where
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

page content time =
  "<div class=\"container\">" ++
    "<ul class=\"nav nav-pills\">" ++ navs ++ "</ul>" ++
    "<div class=\"row\"><div class=\"col-md-12\">" ++ content ++ 
      "<hr><p class=\"text-muted text-right\">Generated on "++time++"</p>"++
  "</div></div></div>" where
  navs = concatMap nav $ nslices
  nav (i, Slice{sname=name}) =
    (printf "<li class=\"hnav\" data-hslice=\"%i\"><a>%s</a></li>" i name) ++
    (printf ("<li class=\"hnav-active active\" data-hslice=\"%i\">" ++
             "<a>%s</a></li>") i name)

html body =
  "<!DOCTYPE html><html lang=\"en\"><head>" ++
    "<meta charset=\"utf-8\">" ++
    "<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">" ++
    "<meta name=\"viewport\" content=\"width=device-width, " ++ 
            "initial-scale=1\">" ++
    "<title>Hinance</title>" ++
    "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com" ++
                                 "/bootstrap/3.3.1/css/bootstrap.min.css\">"++
    "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com" ++
                           "/bootstrap/3.3.1/css/bootstrap-theme.min.css\">"++
    "</head>" ++
  "<body>" ++ body ++
    "<script src=\"https://ajax.googleapis.com/ajax/libs" ++ 
                    "/jquery/1.11.1/jquery.min.js\"></script>" ++
    "<script src=\"https://maxcdn.bootstrapcdn.com" ++
                    "/bootstrap/3.3.1/js/bootstrap.min.js\"></script>" ++
    "<script type=\"text/javascript\" src=\"hinance.js\"></script>" ++
    "</body></html>"
