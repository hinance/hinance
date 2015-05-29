// Copyright 2015 Oleg Plakhotniuk
//
// This file is part of Hinance.
//
// Hinance is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Hinance is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Hinance.  If not, see <http://www.gnu.org/licenses/>.

htabdata = {};

hshow = function(elem, show) {
  if (show) {elem.removeAttribute('style');}
  else {elem.setAttribute('style', 'display:none');}}

htabupdate = function(ntab) {
  var bodyvis = document.getElementById('htabrows-'+ntab);
  var bodyhid = document.getElementById('htabrows-hid-'+ntab);
  var rowsvis = bodyvis.childNodes;
  var d = htabdata[ntab];
  while (rowsvis.length > 0) {
    bodyhid.appendChild(rowsvis[0]);}
  for (var i = d.from; i < d.to; i++) {
    var j = d.asc ? i : d.rows - 1 - i;
    var row=bodyhid.getElementsByClassName('htab-srt'+d.srt+'-'+ntab+'-'+j)[0];
    bodyvis.appendChild(row);}
  if (d.rows > hdevrows) {
    hshow(document.getElementById('htabprev-disabled-'+ntab), d.from == 0);
    hshow(document.getElementById('htabprev-'+ntab), d.from > 0);
    hshow(document.getElementById('htabnext-disabled-'+ntab), d.to == d.rows);
    hshow(document.getElementById('htabnext-'+ntab), d.to < d.rows);
    document.getElementById('htabfrom-'+ntab).innerHTML = d.from+1;
    document.getElementById('htabto-'+ntab).innerHTML = d.to;}}

htabtouch = function(ntab, rows) {
  if (!(ntab in htabdata)) {htabdata[ntab] = {
      from: 0, to: Math.min(hdevrows, rows),
      asc: false, srt: 'date', rows: rows};}}

htabprev = function(ntab, rows) {
  htabtouch(ntab, rows);
  var d = htabdata[ntab];
  d.from = Math.max(0, d.from - hdevrows);
  d.to = d.from + hdevrows;
  htabupdate(ntab);}

htabnext = function(ntab, rows) {
  htabtouch(ntab, rows);
  var d = htabdata[ntab];
  d.to = Math.min(d.rows, d.to + hdevrows);
  d.from = d.to - hdevrows;
  htabupdate(ntab);}

htabsrt = function(ntab, srt, rows) {
  htabtouch(ntab, rows);
  var d = htabdata[ntab];
  d.asc = srt == d.srt ? !d.asc : true;
  d.srt = srt;
  htabupdate(ntab);}
