module Hinance.WebPages (webpages) where
import Hinance.Changes
import Hinance.Diag
import Hinance.User.Data
import Hinance.User.Type
import Text.Printf
import Text.Show.Pretty

webpages = map (\(k,v) -> (k, html $ page v "TODO")) $
 [("home.html", homepage), ("diag.html", diagpage)] ++
 [(printf "slice%i.html" n, slicepage s) | (n, s) <- nslices]

nslices = zip [0..] slices :: [(Integer, Slice)]

homepage = "<h1>Welcome!</h1>"

slicepage slice = alert ++ buttons ++ figact ++ figdiff ++ figplan where
  alert | diagcount == 0 = ""
        | otherwise =
          "<div class=\"alert alert-warning\">" ++ 
            "<strong>Warning!</strong> There are " ++ (show diagcount) ++
            " validation errors " ++
            "(<a href=\"diag.html\">read full report</a>).</div>"
  buttons =
    "<div class=\"btn-group btn-group-lg btn-group-justified\">" ++
      "<a class=\"btn btn-lg btn-default\">Older</a>" ++
      "<a class=\"btn btn-lg btn-default\">Months</a>" ++
      "<a class=\"btn btn-lg btn-default\">Newer</a></div><br>"
  figact = figure "Actual" chgsact slice
  figdiff = figure "Actual - Planned =" chgsdiff slice
  figplan = figure "Planned" chgsplan slice

figure title chgs slice =
  "<div class=\"panel panel-default\">" ++ 
    "<div class=\"panel-heading\">" ++
      "<h3 class=\"panel-title\">" ++ title ++ "</h3></div>"++
    "<div class=\"panel-body text-center\">" ++ svg ++ labels ++ "</div>" ++
  "</div>" where
  labels="<ul class=\"list-inline\">"++(concatMap label$scategs slice)++"</ul>"
  label c = printf (
    "<li><span class=\"label\" style=\"color:%s;background-color:%s\"" ++
      ">%s: %i</span></li>") (scfg c) (scbg c) (scname c) (div amt 100) where
    amt :: Integer
    amt = sum $ map camount $ catchgs c $ slicechgs slice chgs
  svg = "TODO"

catchgs c = filter (\Change{ctags=ts}->any (flip elem$ts) $ sctags c)
slicechgs s = filter (\Change{ctags=ts}->all (flip elem$ts) $ stags s)

diagpage =
  (printf "<h3>Checks (%i):</h3>" (length diagchecks)) ++
  (printf "<pre>%s</pre>" (ppShow diagchecks)) ++
  (printf "<h3>Changes without groups (%i):</h3>" (length diagnogrp)) ++
  (printf "<pre>%s</pre>" (ppShow diagnogrp)) ++
  (printf "<h3>Unbalanced groups (%i):</h3>" (length diagugrps)) ++
  (printf "<pre>%s</pre>" (ppShow diagugrps)) ++
  (printf "<h3>Slices mismatch (%i):</h3>" (length diagslicesflat)) ++
  (printf "<pre>%s</pre>" (ppShow diagslices))

page content time =
  "<div class=\"container\">" ++
    "<ul class=\"nav nav-pills\">" ++ navs ++ "</ul>" ++
    "<div class=\"row\"><div class=\"col-md-12\">" ++ content ++ 
      "<hr><p class=\"text-muted text-right\">Generated on "++time++"</p>"++
  "</div></div></div>" where
  navs = concatMap nav $ nslices
  nav (i, Slice{sname=name}) = concat [
    printf ("<li class=\"" ++ cls ++ "\" data-hslice=\"%i\" " ++ hide ++
            "><a>%s</a></li>") i name | cls <- ["hnav", "hnav-active active"]]

hide = "style=\"display:none\""

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
