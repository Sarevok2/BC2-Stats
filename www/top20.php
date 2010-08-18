<?php

function formatTime($time) {
	$time = intval($time/60);
	$minutes = $time%60;
	$time = intval($time/60);
	$hours = $time%24;
	$days = intval($time/24);

	$string;
	if ($days > 0) {$string = $days."d ".$hours."h ".$minutes."m";}
	elseif ($hours > 0) {$string = $hours."h ".$minutes."m";}
	else {$string = $minutes."m";}

	return $string;
}

function createLeadersTable($plat) {
	$result = mysql_query("SELECT * FROM mainstats, bc2users WHERE mainstats.persona = bc2users.persona AND 
		bc2users.platform=$plat ORDER BY (awardscore + combatscore) DESC LIMIT 20")
	or die("could not retrieve stats: " . mysql_error());

	$platform;
	if ($plat==1) $platform="pc";
	elseif ($plat==2) $platform="360";
	elseif ($plat==3) $platform="ps3";

	echo "<table class='statgrid standard'><tr><th>Name</th><th>Position</th><th>Score</th><th>Score/min</th>
		<th>Kills</th><th>Deaths</th><th>K/D ratio</th><th>Time Played</th></tr>";

	while ($row = mysql_fetch_array($result)) {
		$score = $row['combatscore']+$row['awardscore'];
		$kdratio = round($row['kills']/$row['deaths'],2);
		$scorepm = round($score/$row['timeplayed']*60,2);
		echo "<tr><td><a href='showstats.php?username=".$row['username']."&platform=$platform'>".$row['username'].
			"</a></td><td>".$row['position']."</td><td>$score</td><td>$scorepm</td><td>".$row['kills'].
			"</td><td>".$row['deaths']."</td><td>$kdratio</td><td>".formatTime($row['timeplayed'])."</td></tr>";
	}
	echo "</table>";
}

echo "<html><head><link rel='stylesheet' type='text/css' href='style.css' />";
echo "<script type='text/javascript' src='scripts.js'></script></head><body onload='init()'><div id='content'>";

include("navbar.php");
include("connect.php");




echo "<div class='statArea'>";

echo "<ul id='tabs'>";
echo "<li><a href='#pc'>PC</a></li>";
echo "<li><a href='#360'>Xbox 360</a></li>";
echo "<li><a href='#ps3'>PS3</a></li>";
echo "</ul>";

echo "<div class='itemTabs' id='pc'>";
createLeadersTable(1);
echo "</div><div class='itemTabs' id='360'>";
createLeadersTable(2);
echo "</div><div class='itemTabs' id='ps3'>";
createLeadersTable(3);
echo "</div>";

echo "</div></body></html>";
?>
