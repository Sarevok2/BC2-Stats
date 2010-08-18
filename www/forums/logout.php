<?php
session_start();
session_destroy();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";
include "../navbar.php";
echo "Logged out.  Click <a href='forumindex.php'>here</a> to return to the main forum.";
echo "</div></body></html>";
?>
