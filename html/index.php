<!DOCTYPE html>
<html>
<head>
<title>qCut Variations</title>
</head>
<style>
a:link{color:#000000; background-color:transparent; text-decoration:none}
a:visited{color:#009000; background-color:transparent; text-decoration:none}
a:hover{color:#900000;background-color:transparent; text-decoration:underline}
a:active{color:#900000;background-color:transparent; text-decoration:underline}
body.ex{margin-top: 0px; margin-bottom:25px; margin-right: 25px; margin-left: 25px;}
</style>

<body class="ex" bgcolor="#EEEEEE">
<body style="font-family: arial;font-size: 20px;font-weight: bold;color:#900000;">
<hr>
<h1>Q CUT Variations</h1>

<p>If you find empty files/plots let me know so I can fix them.</p>

<?php
print "<p>Configuration files used</p>\n";
print '<ul>';
$output = shell_exec('ls -t *.env *.py-template');
$f = explode("\n",$output);
foreach ($f as &$file) {
  if ($file != "") {
    print '<li> <a href="' . $file . '">' . $file . '</a>';
  }
}
print '</ul>';
print "<p>Find out the cross sections and matching efficiencies</p>\n";
print '<ul>';
$output = shell_exec('ls -t *.txt');
$f = explode("\n",$output);
foreach ($f as &$file) {
  if ($file != "") {
    print '<li> <a href="' . $file . '">' . $file . '</a>';
  }
}
print '</ul>';
print "<p>Follow the plots of the cut variations.</p>\n";
print '<ul>';
$output = shell_exec('ls -t *.png');
$f = explode("\n",$output);
foreach ($f as &$file) {
  if ($file != "") {
    print '<li> <a href="' . $file . '">' . $file . '</a>';
  }
}
print '</ul>';
?>
<hr>
<p style="font-family: arial;font-size: 10px;font-weight: bold;color:#900000;">
<!-- hhmts start -->
Modified: Fri May  1 13:11:14 EDT 2015
<a href="http://web.mit.edu/physics/people/faculty/paus_christoph.html">Christoph Paus</a>
<!-- hhmts end -->
</p>
</body></html>
