<?php
session_start();
include("connect.php");
if ($_SESSION['uid']) {

  mysql_query("INSERT INTO posts (threadid,posterid,posttime,text) VALUES ($_POST[threadid], $_SESSION[uid], " . time() . 
    ", '$_POST[text]')") or die("Unable to post: " . mysql_error());

  $postid = mysql_insert_id();
  mysql_query("UPDATE forumusers SET postcount=postcount+1 WHERE userid = $_SESSION[uid]");

  mysql_query("UPDATE threads SET lastpostid=$postid,numreplies=numreplies+1 WHERE threadid=$_POST[threadid]");

	mysql_query("UPDATE forumcategories SET posts=posts+1 WHERE catindex=$_POST[category]");
}
else die("Not logged in");
mysql_close($con);

header("location:showthread.php?category=$_POST[category]&threadid=" . $_POST['threadid']);
?>
