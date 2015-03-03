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
cfgcellspace = 10
cfgmarkheight = 30 :: Integer
cfgmarkspace = 10
cfgmarkofsx = 35
cfgmarkofsy = 20
cfgmarginleft = 5
cfgmarginright = 5
cfgmargintop = 5
cfgmarginbottom = 5
cfgcolumnheight = 400

stepmonth = 365 * 2 * 3600

webpages = concatMap (devicepages "TODO") [
  Device{dname="dtp", dlen=16},
  Device{dname="mob", dlen=5}]

data Device = Device {dname::String, dlen::Integer}

devicepages time dev = map (\(k,v) -> (k, html $ page v time dev)) $
 [(pfx ++ "home.html", homepage), (pfx ++ "diag.html", diagpage)] ++
 [(printf "%sslice%i-step%i.html" pfx n step, slicepage s n step 0 dev)
  | (n, s) <- zip idxs slices, step <- steps $ dlen dev]
 where pfx = (dname dev) ++ "-"

defstep len = div (tmax - tmin + len) len where
  tmin = minimum $ map ctime chgsact
  tmax = maximum $ map ctime chgsact

steps len = [stepmonth, defstep len]

homepage = "<h1>Welcome!</h1>"

slicepage slice nslice step ofs dev =
  alert ++ buttons ++ figact ++ figdiff ++ figplan ++ params where
  alert | diagcount == 0 = ""
        | otherwise =
          "<div class=\"alert alert-warning\">" ++ 
            "<strong>Warning!</strong> There are " ++ (show diagcount) ++
            " validation errors " ++
            "(<a href=\"" ++ pfx ++ "diag.html\">read full report</a>).</div>"
  buttons =
    "<div class=\"btn-group btn-group-lg btn-group-justified\">" ++
      "<a class=\"btn btn-lg btn-default\">Older</a>" ++ stepbtns ++ 
      "<a class=\"btn btn-lg btn-default\">Newer</a></div><br>"
  stepbtns = (concat [printf (
    "<a class=\"btn btn-lg btn-default hstep\" data-hstep=\"%i\" " ++ hide ++
    ">%s</a>") s n | (s,n)<-zip (steps len) ["Months", "Actual"]])
  params = "<span id=\"hslice-params\" " ++
    (printf "data-hslice=\"%i\" " nslice) ++
    (printf "data-hstep=\"%i\"></span>" step)
  figact = figure "Actual" chgsact slice step ofs len True
  figdiff = figure "Actual - Planned =" chgsdiff slice step ofs len False
  figplan = figure "Planned" chgsplan slice step ofs len True
  len = (dlen dev)
  pfx = (dname dev) ++ "-"

figure title allchgs slice step ofs len posneg =
  "<div class=\"panel panel-default\">" ++ 
    "<div class=\"panel-heading\">" ++
      "<h3 class=\"panel-title\">" ++ title ++ "</h3></div>"++
    "<div class=\"panel-body text-center\">" ++ svg ++ labels ++ "</div>" ++
  "</div>" where
  labels="<ul class=\"list-inline\">"++(concatMap label$scategs slice)++"</ul>"
  label c = printf (
    "<li><span class=\"label\" style=\"color:%s;background-color:%s\"" ++
      ">%s: %i</span></li>") (scfg c) (scbg c) (scname c) (div amt 100) where
    amt = sum $ map camount $ catchgs c $ changes
  svg = (printf "<svg width=\"100%%\" viewbox=\"0 0 %i %i\">%s</svg>"
         totalwidth totalheight $ concatMap column icolumns)
  column icolumn = "<g>" ++ 
    "<g " ++
      (printf "transform=\"translate(%i,%i)\">%s</g>" x stackposy stackpos) ++
    "<rect " ++
      (printf "fill=\"none\" stroke=\"%s\" " cfgbdrcol) ++
      (printf "width=\"%i\" height=\"%i\" " cfgcellwidth cfgmarkheight) ++
      (printf "rx=\"%i\" ry=\"%i\" " cfgbdrround cfgbdrround) ++
      (printf "x=\"%i\" y=\"%i\"/>" x marky) ++
    "<text " ++ 
      (printf "text-anchor=\"middle\" fill=\"%s\" " cfgtxtcol) ++
      (printf "x=\"%i\" y=\"%i\">" (x + cfgmarkofsx) (marky + cfgmarkofsy)) ++
      (printf "%i</text>" icolumn) ++
    "<g " ++
      (printf "transform=\"translate(%i,%i)\">%s</g>" x stacknegy stackneg) ++
    "</g>" where
    svgstack [] = ""
    svgstack (cell:cells) = "<g>" ++ justcell ++ tailcells ++ "</g>" where
      justcell = "<a>" ++
        "<rect " ++
          (printf "fill=\"%s\" stroke=\"%s\" " bgcolor cfgbdrcol) ++
          (printf "width=\"%i\" height=\"%i\" " cfgcellwidth height) ++
          (printf "x=\"0\" y=\"%i\" " diry) ++
          (printf "rx=\"%i\" ry=\"%i\"/>" cfgbdrround cfgbdrround) ++
        "<text " ++ 
          (printf "text-anchor=\"middle\" fill=\"%s\" " fgcolor) ++
          (printf "x=\"%i\" y=\"%i\">" cfgmarkofsx texty) ++
          (printf "%i</text></a>" (div amount 100))
      tailcells | null cells = ""
                | otherwise = (printf "<g transform=\"translate(0,%i)\">%s</g>"
                               nexty (svgstack cells))
      bgcolor = scbg categ
      fgcolor = scfg categ
      amount = fcamount cell
      height = fcheight cell
      diry | amount > 0 = - height | otherwise = 0
      nexty | amount > 0 = - height | otherwise = height
      texty = diry + cfgmarkofsy
      categ = fccateg cell
    stackpos = svgstack $ stackcells posamtftr poscatftr
    stackneg = svgstack $ stackcells negamtftr negcatftr
    stackcells amftr catftr =
      figurecells (scategs slice) normheight amftr catftr $ colchgs icolumn
    stackposy = cellsheightpos + cfgmargintop
    stacknegy = marky + cfgmarkspace + cfgmarkheight
    x = cfgmarginleft + (icolumn * cellwspace)
    marky = cfgmargintop + cellsheightpos + cfgmarkspace
  icolumns = [ofs..ofs+len]
  totalwidth = cfgmarginleft + (len*cellwspace) - cfgcellspace + cfgmarginright
  totalheight = cfgmargintop + cellsheightpos +
                cfgmarkspace + cfgmarkheight + cfgmarkspace +
                cellsheightneg + cfgmarginbottom
  cellwspace = cfgcellwidth + cfgcellspace
  cellsheightpos = maxcolheight normheight posamtftr poscatftr
  cellsheightneg = maxcolheight normheight negamtftr negcatftr
  normheight = maximum [1, normheightpos + normheightneg]
  normheightpos = maxcolheight cfgcolumnheight posamtftr poscatftr
  normheightneg = maxcolheight cfgcolumnheight negamtftr negcatftr
  posamtftr | posneg = (> 0) | otherwise = (/= 0)
  negamtftr | posneg = (< 0) | otherwise = (/= 0)
  poscatftr | posneg = (/= 0) | otherwise = (> 0)
  negcatftr | posneg = (/= 0) | otherwise = (< 0)
  maxcolheight scale amftr catftr = maximum $ map colheight icolumns where
    colheight = sum . (map fcheight) . cells . colchgs
    cells = figurecells (scategs slice) scale amftr catftr
  changes = slicechgs slice allchgs
  colchgs icolumn = filter (\Change{ctime=t} -> t >= tmin && t < tmax) changes
    where tmin = (minimum $ map ctime chgsact) + (step * icolumn)
          tmax = tmin + step

data FigureCell = FigureCell {fccateg::SliceCateg, fcamount::Integer,
                              fcheight::Integer} deriving (Show, Read, Eq, Ord)

figurecells categs normh amftr catftr changes =
  sortBy (on compare $ abs.fcamount) $ filter cellftr $ map cell categs where
  cellftr = catftr . fcamount
  cell categ=FigureCell{fccateg=categ, fcamount=amount, fcheight=height} where
    amount = sum $ filter amftr $ map camount $ catchgs categ changes
    height = maximum [cfgmarkheight, div ((abs amount)*cfgcolumnheight) normh]

diagpage =
  (printf "<h3>Checks (%i):</h3>" (length diagchecks)) ++
  (printf "<pre>%s</pre>" (ppShow diagchecks)) ++
  (printf "<h3>Changes without groups (%i):</h3>" (length diagnogrp)) ++
  (printf "<pre>%s</pre>" (ppShow diagnogrp)) ++
  (printf "<h3>Unbalanced groups (%i):</h3>" (length diagugrps)) ++
  (printf "<pre>%s</pre>" (ppShow diagugrps)) ++
  (printf "<h3>Slices mismatch (%i):</h3>" (length diagslicesflat)) ++
  (printf "<pre>%s</pre>" (ppShow diagslices))

page content time dev =
  "<span id=\"hdev-params\" " ++
    (printf "data-hdefstep=\"%i\" " (defstep $ dlen dev)) ++
    (printf "data-hname=\"%s\"></span>" (dname dev)) ++
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
