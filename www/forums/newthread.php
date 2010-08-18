<?php
session_start();
echo "<html><head><link rel='stylesheet' type='text/css' href='../style.css'></head><body><div id='content'>";
include("../navbar.php");
include("top.php");

if ($_SESSION['uid']) {
  echo "<html>";
  echo "<body>";
  echo "<form action='postthread.php' method='post'>";
  echo "Title: <input type='text' name='title' /><br/>";
  echo "<textarea name='text' rows=10 cols=100></textarea><br/>";
  echo "<input type='hidden' name='category' value=$_GET[category]>";
  echo "<input type='submit' value='Submit'/>";
  echo "</form>";
}
else echo "Not logged in";

echo "</div></body></html>";
