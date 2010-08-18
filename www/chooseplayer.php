<?php

echo "<html><head><link rel='stylesheet' type='text/css' href='style.css' /></head>";
echo "<body><div id='content'>";
include("navbar.php");
echo "<form action='showstats.php'>
<table><tr><td>Username:</td><td><input type='text' name='username' /></td></tr>
<tr><td>Platform:</td><td><select name='platform'>
	<option value='pc'>PC</option>
	<option value='360'>Xbox 360</option>
	<option value='ps3'>PS3</option>
</select></td></tr>
<tr><td><input type='submit' value='Search'></td></tr></table>
</div></body></html>";

?>
