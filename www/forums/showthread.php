<?php
session_start();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";

include("connect.php");
include("../navbar.php");
include("top.php");

mysql_query("UPDATE threads SET numviews=numviews+1 WHERE threadid=" . $_GET['threadid']);

echo "<br/><br/><table style='width:100%'>";

$result = mysql_query("SELECT * FROM posts WHERE threadid = " . $_GET['threadid'])
or die("could not retrieve posts: " . mysql_error());
while ($row = mysql_fetch_array($result)) {
  $usrresult = mysql_query("SELECT username,postcount FROM forumusers WHERE userid = " . $row['posterid'])
    or die("Mysql error: " . mysql_error());
  $usrrow = mysql_fetch_array($usrresult);

  echo "<tr><td style='border-style:none'><table class='forumtable'><tr><th colspan=2 style='font-weight:normal'>";
  echo date("Y/m/d h:ia", $row['posttime']) . "</th></tr>";
  echo "<tr><td width=180>" . $usrrow['username'] . "<br/>Posts: " . $usrrow['postcount']. "</td><td>" . nl2br($row['text']);
  echo "</td></tr></table></td></tr>";
}

echo "</table>";

mysql_close($con);

if ($_SESSION['uid']) {
  echo "<br/><br/>";
  echo "<form action='post.php?' method='post'>";
  echo "<input type='hidden' name='threadid' value='" . $_GET['threadid'] . "'>";
  echo "<textarea name='text' rows=5 cols=100></textarea><br/>";
  echo "<input type='hidden' name='category' value=$_GET[category]>";
  echo "<input type='submit' value='Post'>";
  echo "</form>";
}
echo "</div></body></html>";
?>
