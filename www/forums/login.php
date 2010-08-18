<?php
session_start();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css' /></head><body><div id='content'>";
include("connect.php");
include "../navbar.php";
$username=mysql_real_escape_string($_POST['username']);
$password=mysql_real_escape_string($_POST['password']);
$md5password=mysql_real_escape_string($_POST['md5password']); 
$encrypted_password = md5($md5password);

$sql="SELECT * FROM forumusers WHERE username='$username' and password='$encrypted_password'";
$result=mysql_query($sql);
$count=mysql_num_rows($result);

if ($count == 1) {
  $row = mysql_fetch_array($result);
  $_SESSION['uid'] = $row['userid'];

  echo "Logged in successfully.  Click <a href='forumindex.php'>here</a> to return to the main page.";
}
else echo "Invalid username/password";

echo "</div></body></html>";
mysql_close($con);
?>
