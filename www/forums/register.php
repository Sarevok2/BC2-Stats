<?php

echo "<html><head>
<script type='text/javascript' src='scripts.js'></script>
<link rel='stylesheet' type='text/css' href='../style.css' />
<style type='text/css'>
  td,table {border-style:none}
</style>
</head>
<body><div id='content'>";
include "../navbar.php";
echo "<form action='adduser.php' method='post' onsubmit='return verifyRegistration(user, pass, confpass, md5pass)'>
  <table>
    <tr><td>Username: </td><td><input type='text' name='user'/></td></tr>
    <tr><td>Password: </td><td><input type='password' name='pass'/></td></tr>
    <tr><td>Confirm Password: </td><td><input type='password' name='confpass'/></td></tr>
  <table>
  <input type='hidden' name='md5pass'/>
  <input type='submit' value='Register'/>
</form>

</div></body></html>";
?>
