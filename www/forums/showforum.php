<?php
session_start();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";

include("connect.php");
include("../navbar.php");
include("top.php");

echo "<form action='search.php' method='get' >
	<div style='float:right; padding: 10px 0 2px 0'><input type='text' name='search' />
	<input type='submit' value='Search' /></div>
	</form>";

$result = mysql_query("SELECT * FROM threads");
echo "<table class='forumtable'><tr><th style='width:70%'>Subject</th><th>Replies</th><th>Views</th><th>Original Poster</th><th style='width:20%'>Last Post</th></tr>";

while ($row = mysql_fetch_array($result)) {
	if ($row['category'] == $_GET['category']) {
		$usrresult = mysql_query("SELECT username FROM forumusers where userid = $row[creatoruserid]");
		$usrrow = mysql_fetch_array($usrresult);
		$creatorname = $usrrow['username'];
	  
		$pstresult = mysql_query("SELECT posttime,posterid FROM posts WHERE (postid = $row[lastpostid])");
		$pstrow = mysql_fetch_array($pstresult);
		$lastposterid = $pstrow['posterid'];
		$lastposttime = date("Y/m/d h:ia", $pstrow['posttime']);

		$usrresult = mysql_query("SELECT username FROM forumusers where userid = $lastposterid");
		$usrrow = mysql_fetch_array($usrresult);
		$lastpostername = $usrrow['username'];

		echo "<tr><td><a href='showthread.php?category=$row[category]&threadid=$row[threadid]'>$row[title]</a></td>";
		echo "<td>$row[numreplies]</td><td>$row[numviews]</td><td>$creatorname</td><td>$lastposttime<br/> by $lastpostername</td></tr>";
	}
}
echo "</table>";


if ($_SESSION['uid']) {
  echo "<br/><br/><a href='newthread.php?category=$_GET[category]' style='color: #999900'>New Topic</a>";
}
echo "</div></body></html>";
?>
