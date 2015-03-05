var htabdata = {};

htabupdate = function(ntab) {
  var bodyvis = document.getElementById('htabrows-'+ntab);
  var bodyhid = document.getElementById('htabrows-hid-'+ntab);
  var rowsvis = bodyvis.children;
  var d = htabdata[ntab];
  for (var i = 0; i < rowsvis.length; i++) {
    bodyhid.appendChild(rowsvis[i]);}
  for (var i = d.from; i < d.to; i++) {
    var j = d.asc ? i : d.rows - 1 - i;
    var row = bodyhid.getElementsByClassName('htab-srt'+d.srt+'-'+ntab+'-'+j);
    bodyvis.appendChild(row);}
  show(document.getElementById('htabprev-disabled-'+ntab), d.from == 0);
  show(document.getElementById('htabprev-'+ntab), d.from > 0);
  show(document.getElementById('htabnext-disabled-'+ntab), d.to == d.rows);
  show(document.getElementById('htabnext-'+ntab), d.to < d.rows);
  document.getElementById('htabfrom-'+ntab).innerHTML(d.from);
  document.getElementById('htabto-'+ntab).innerHTML(d.to);}

htabtouch = function(ntab, rows) {
  if (!ntab in htabdata) {htabdata[ntab] = {
      from: 0, to: hdevrows, asc: false, srt: 'date', rows: rows};}}

htabprev = function(ntab, rows) {
  htabtouch(ntab, rows);
  var d = htabdata[ntab];
  d.from = Math.max(0, d.from - hdevrows);
  d.to = d.from + hdevrows;
  htabupdate(ntab);}

htabnext = function(ntab, rows) {
  htabtouch(ntab, rows);
  var d = htabdata[ntab];
  d.to = Math.min(d.rows-1, d.to + hdevrows);
  d.from = d.to - hdevrows;
  htabupdate(ntab);}

htabsrt = function(ntab, srt, rows) {
  htabtouch(ntab, rows);
  var d = htabdata[ntab];
  if (srt == d.srt) {d.asc = !d.asc;}
  d.srt = srt;
  htabupdate(ntab);}
