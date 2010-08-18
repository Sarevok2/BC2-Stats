<?php
session_start();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";
include("forumglobals.php");
include("connect.php");
include("../navbar.php");
include("top.php");

echo "<form action='search.php' method='get' >
	<div style='float:right; padding: 10px 0 2px 0'><input type='text' name='search' />
	<input type='submit' value='Search' /></div>
	</form>";

$result = mysql_query("SELECT * FROM forumcategories");
echo "<br/><table class='forumtable'><tr><th>Category</th><th>Threads</th><th>Posts</th></tr>";
while ($row = mysql_fetch_array($result)) {
	echo "<tr><td><a href='showforum.php?category=".$row['catindex']."'>".$row['title']."</a><br/>".
		"<div style='color: #999999'> - ".$row['subtitle']."</div></td><td>".$row['threads']."</td><td>".$row['posts']."</td></tr>";
}
echo "</table>";
echo "</div></body></html>";
?>
