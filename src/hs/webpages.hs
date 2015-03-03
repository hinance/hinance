module Hinance.WebPages (webpages) where
import Data.Function
import Data.List
import Hinance.Changes
import Hinance.Diag
import Hinance.User.Data
import Hinance.User.Type
import Text.Printf
import Text.Show.Pretty

cfgbdrcol = "#DDD"
cfgtxtcol = "#333"
cfgbdrround = 8 :: Integer
cfgcellwidth = 70 :: Integer
cfgcellspace = 10 :: Integer
cfgmarkheight = 30 :: Integer
cfgmarkspace = 10 :: Integer
cfgmarkofsx = 35 :: Integer
cfgmarkofsy = 20 :: Integer
cfgmarginleft = 5 :: Integer
cfgmarginright = 5 :: Integer
cfgmargintop = 5 :: Integer
cfgmarginbottom = 5 :: Integer

webpages = map (\(k,v) -> (k, html $ page v "TODO")) $
 [("home.html", homepage), ("diag.html", diagpage)] ++
 [(printf "slice%i.html" n, slicepage s 2600000 0 16)
  | (n, s) <- zip idxs slices]

homepage = "<h1>Welcome!</h1>"

slicepage slice step ofs len = alert++buttons++figact++figdiff++figplan where
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
  figact = figure "Actual" chgsact slice step ofs len True
  figdiff = figure "Actual - Planned =" chgsdiff slice step ofs len False
  figplan = figure "Planned" chgsplan slice step ofs len True

figure title changes slice step ofs len posneg =
  "<div class=\"panel panel-default\">" ++ 
    "<div class=\"panel-heading\">" ++
      "<h3 class=\"panel-title\">" ++ title ++ "</h3></div>"++
    "<div class=\"panel-body text-center\">" ++ svg ++ labels ++ "</div>" ++
  "</div>" where
  labels="<ul class=\"list-inline\">"++(concatMap label$scategs slice)++"</ul>"
  label c = printf (
    "<li><span class=\"label\" style=\"color:%s;background-color:%s\"" ++
      ">%s: %i</span></li>") (scfg c) (scbg c) (scname c) (div amt 100) where
    amt = sum $ map camount $ catchgs c $ slicechgs slice changes
  svg = (printf "<svg width=\"100%%\" viewbox=\"0 0 %i %i\">%s</svg>"
         totalwidth totalheight (concatMap column icolumns))
  column icolumn = "<g>" ++ stackpos ++
    "<rect " ++
      (printf "width=\"%i\" height=\"%i\" " cfgcellwidth cfgmarkheight) ++
      (printf "fill=\"none\" stroke=\"%s\" " cfgbdrcol) ++
      (printf "rx=\"%i\" ry=\"%i\" " cfgbdrround cfgbdrround) ++
      (printf "x=\"%i\" y=\"%i\"/>" x marky) ++
    "<text " ++ 
      (printf "text-anchor=\"middle\" fill=\"%s\" " cfgtxtcol) ++
      (printf "x=\"%i\" y=\"%i\">" (x + cfgmarkofsx) (marky + cfgmarkofsy)) ++
      (printf "%i</text>" icolumn) ++ stackneg ++ "</g>" where
    stackpos = ""
    stackneg = ""
    x = cfgmarginleft + (icolumn * cellwspace)
    marky = cfgmargintop + cellsheightpos + cfgmarkspace
  icolumns = [ofs..ofs+len]
  totalwidth = cfgmarginleft + (len*cellwspace) - cfgcellspace + cfgmarginright
  totalheight = cfgmargintop + cellsheightpos +
                cfgmarkspace + cfgmarkheight + cfgmarkspace +
                cellsheightneg + cfgmarginbottom
  cellwspace = cfgcellwidth + cfgcellspace
  cellsheightpos = 100
  cellsheightneg = 100
  posamtftr | posneg = (> 0) | otherwise = (/= 0)
  negamtftr | posneg = (< 0) | otherwise = (/= 0)
  poscatftr | posneg = (/= 0) | otherwise = (> 0)
  negcatftr | posneg = (/= 0) | otherwise = (< 0)
  maxcolamountpos = maxcolamount posamtftr poscatftr
  maxcolamountneg = maxcolamount negamtftr negcatftr
  maxcolamount amftr catftr = maximum $ map colamount icolumns where 
    colamount = abs.sum.(filter catftr).(map catamount).catschgs.colchgs
    catschgs chgs = map (flip catchgs $ chgs) (scategs slice)
    catamount = sum . (filter amftr) . (map camount)
  colchgs icolumn = filter (\Change{ctime=t} -> t >= tmin && t < tmax) changes
    where tmin = (minimum $ map ctime chgsact) + (step * icolumn)
          tmax = tmin + step

data FigureCell = FigureCell {fccateg::SliceCateg, fcamount::Integer,
                              fcheight::Integer} deriving (Show, Read, Eq, Ord)

figurecells changes categs scale amftr catftr =
  sortBy (compare `on` fcheight) $ filter cellftr $ map cell categs where
  cellftr = catftr . fcamount
  cell categ=FigureCell{fccateg=categ, fcamount=amount, fcheight=height} where
    amount = sum $ filter amftr $ map camount $ catchgs categ changes
    height = (abs amount) * scale

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
  navs = concatMap nav $ zip idxs slices
  nav (i, Slice{sname=name}) = concat [
    printf ("<li class=\"%s\" data-hslice=\"%i\" "++hide++"><a>%s</a></li>")
    cls i name | cls <- ["hnav", "hnav-active active"]]

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

--TODO: move to report module
catchgs c = filter (\Change{ctags=ts}->any (flip elem$ts) $ sctags c)
slicechgs s = filter (\Change{ctags=ts}->all (flip elem$ts) $ stags s)
idxs = [(toInteger 0)..]
