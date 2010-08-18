<?php
include("connect.php");

echo "<table class='forumtable'><tr><td><a href='forumindex.php'>Forum</a>";
if ($_GET['category']) {
	$result = mysql_query("SELECT title FROM forumcategories WHERE catindex=".$_GET['category']);
	$row = mysql_fetch_array($result);
	echo " - <a href='showforum.php?category=".$_GET['category']."'>".$row['title']."</a>";
}
if ($_GET['threadid']) {
  $result = mysql_query("SELECT title FROM threads WHERE threadid = " . $_GET['threadid']);
  $row = mysql_fetch_array($result);
  echo ":<br/>- " . $row['title'];
}
echo "</td><td width=300>";

if ($_SESSION['uid']) {
  // May need to verify username/password here
  $result = mysql_query("SELECT username FROM forumusers WHERE userid = " . $_SESSION['uid']);
  $row = mysql_fetch_array($result);
 
  echo "Welcome " . $row['username'] . "<br/>";
  echo "<a href='logout.php'>Logout</a>";
}
else {
  echo "<script type='text/javascript' src='scripts.js'></script>
  <form action='login.php' method='post' onsubmit='md5hash(password, md5password)'>
  <table class='logintable'>
  <tr><td>Username: </td><td><input type='text' name='username' tabindex=1 /></td><td><input type='submit' value='Login' tabindex=3 /></td></tr>
  <tr><td>Password: </td><td><input type='password' name='password' tabindex=2 /></td>
	<td style='min-width: 110'><a href='register.php' tabindex=4>Create Account</a></td></tr>
  </table>
  <input type='hidden' name='md5password'>
  </form>";
}
echo "</td></tr></table>";
?>
