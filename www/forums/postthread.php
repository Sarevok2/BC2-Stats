<?php
session_start();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css'></head><body><div id='content'>";
include('connect.php');
include("../navbar.php");
include('top.php');

$now = time();
$uid = $_SESSION['uid'];

if ($uid) {
	if ($_POST['title'] == '' || $_POST['text'] == '') die ('Fields cannot be empty');
	$sql = "INSERT INTO threads (creatoruserid, title, creationtime,  numreplies, numviews, category) VALUES ($uid, 
		'$_POST[title]', $now, 0, 0, $_POST[category])";
	mysql_query($sql, $con) or die("MySQL Error: " . mysql_error());
	$threadId = mysql_insert_id();

	$sql = "INSERT INTO posts (threadid, posterid, posttime, text) VALUES ($threadId, $uid, $now, '$_POST[text]')";
	  mysql_query($sql, $con) or die("MySQL Error: " . mysql_error());
  
	$sql = "UPDATE threads SET lastpostid=" . mysql_insert_id() . " WHERE threadid=" . $threadId; 
	mysql_query($sql, $con) or die("MySQL Error: " . mysql_error());
  
	mysql_query("UPDATE forumusers SET postcount=postcount+1 WHERE userid = " . $uid);

	mysql_query("UPDATE forumcategories SET posts=posts+1, threads=threads+1 WHERE catindex=$_POST[category]");

	echo "Posted successfully.  Click <a href='showthread.php?category=$_POST[category]&threadid=" . $threadId . ">
		here</a> to return to the thread.";
}
else echo "Not logged in";
mysql_close($con);
echo "</div></body></html>";
