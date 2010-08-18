<?php
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";

include("connect.php");
include("../navbar.php");
include("top.php");

echo "<br/>Results";

$searchstring = trim($_GET['search']);
$index = 0;
$threadids = array();

$result = mysql_query("SELECT threadid FROM threads WHERE title LIKE '%$searchstring%'");

while ($row = mysql_fetch_array($result)) {
  $threadids[$index++] = $row['threadid'];
}

$result = mysql_query("SELECT threadid FROM posts WHERE text LIKE '%$searchstring%'");
while ($row = mysql_fetch_array($result)) {
  $threadids[$index++] = $row['threadid'];
}

$tids = array_unique($threadids);
echo "<table class='forumtable'>";
foreach ($tids as $tid) {
  $result = mysql_query("SELECT title, category FROM threads WHERE threadid = $tid");
  $row = mysql_fetch_array($result);
  echo "<tr><td><a href='showthread.php?category=$row[category]&threadid=$tid'>$row[title] $tid</a></td></tr>";
}
echo "</table>";

echo "</div></body></html>";
?>
