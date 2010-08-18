<?php
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";
include("connect.php");
include("../navbar.php");

$user = mysql_real_escape_string($_POST['user']);
$pass = mysql_real_escape_string($_POST['pass']);
$confpass = mysql_real_escape_string($_POST['confpass']);
$md5pass = mysql_real_escape_string($_POST['md5pass']);
$encpass = md5($md5pass);


mysql_query("INSERT INTO forumusers (username,password,postcount) VALUES ('" . $user . "', '" . $encpass . "', " . 0 . ")")
or die("Failed to add user: " . mysql_error());
echo "Added new user successfully.  Click <a href='forumindex.php'>here</a> to return to the main page and login.";
echo "</div></body></html>";
?>
