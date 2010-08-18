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

echo "<html><head><link rel='stylesheet' type='text/css' href='style.css' />";
echo "<script type='text/javascript' src='scripts.js'></script></head><body onload='init()'><div id='content'>";

include("navbar.php");
include("connect.php");

$logfile = "/home/sarevok/scripts/bc2/logs/bc2log.txt";
$scriptdir = "/home/sarevok/scripts/bc2";

$username = $_GET['username'];
$platform = $_GET['platform'];
$platformnum;
if ($platform == "pc") {$platformnum = 1;}
elseif ($platform == "360") {$platformnum = 2;}
elseif ($platform == "ps3") {$platformnum = 3;}

$result = mysql_query("SELECT * FROM bc2users WHERE username = '" . $username . "' AND platform = " . $platformnum)
or die("could not retrieve stats: " . mysql_error());

$numrows = mysql_num_rows($result);
if ($numrows == 0) {
	//If the user is not already in the database, 
	$result = mysql_query("SELECT * FROM pendingusers WHERE username = '" . $username . "' AND platform = " . $platformnum)
	or die("could not retrieve stats: " . mysql_error());
	$numrows = mysql_num_rows($result);
	if ($numrows == 0) {
		mysql_query("INSERT INTO pendingusers VALUES('".$username."', ".$platformnum.", ".time().", 0)")
		or die("Mysql error: " . mysql_error());
		$cmd = "cd $scriptdir; ./updateone.pl -n $username $platform >> $logfile 2>&1 &";
		exec($cmd);
		echo "Player not yet in database.  Updating now.  Please check again in 2 minutes";
	}
	else {
		$row = mysql_fetch_array($result);
		if ($row['nonexistant'] != 0) echo "User does not exist in EA's database";
		elseif (time() - $row['lastupdate'] > 0) {//if user has been pending for over 5 minutes, something's wrong
			exec("cd $scriptdir; perl updateone.pl -n $username $platform >> $logfile 2>&1 &");
			echo "Player not yet in database.  Updating now.  Please check again in 2 minutes";
		}
		else echo "Users stats are being updated";
	}	
	
	echo "</body></html>";
	exit(0);
}

$row = mysql_fetch_array($result);

$persona = $row['persona'];

//If the players stats haven't been updated in the last hour, update them
if (time() - $row['lastupdate'] > 3600) {
	exec("cd $scriptdir; ./updateone.pl -u $persona $platform > $logfile 2>&1 &");
}

$result = mysql_query("SELECT * FROM mainstats WHERE persona = " . $persona)
or die("could not retrieve stats: " . mysql_error());


$numrows = mysql_num_rows($result);
$maxtime = 0;
$maxtimeindex = 0;
for ($i=0; $i<$numrows; $i++) {
	$rows[$i] = mysql_fetch_array($result);
	if ($rows[$i]['time'] > $maxtime) {
		$maxtime = $rows[$i]['time'];
		$maxtimeindex = $i;
	}
}
$row = $rows[$maxtimeindex];
$lastupdatetime = $row['time'];
$kills = $row['kills'];
$deaths = $row['deaths'];
if ($row['deaths'] == 0) {$kdratio=0;}
else {$kdratio = round($row['kills'] / $row['deaths'],2);}
$totalscore = $row['combatscore'] + $row['awardscore'];
if ($row['timeplayed'] == 0) {$scorepermin = 0;}
else {$scorepermin = round($totalscore / ($row['timeplayed']/60),2);}
$timeplayed = $row['timeplayed'];
$position = $row['position'];
$assaultscore = $row['assaultscore'];
$medicscore = $row['medicscore'];
$reconscore = $row['reconscore'];
$engiscore = $row['engiscore'];
$vehiclescore = $row['vehiclescore'];
$combatscore = $row['combatscore'];
$awardscore = $row['awardscore'];



$result = mysql_query("SELECT * FROM weeklystats WHERE persona = " . $persona . " ORDER BY time DESC LIMIT 3")
or die("could not retrieve stats: " . mysql_error());

$row = mysql_fetch_array($result);
$wksts = array();
$wksts[0] = array();
$wksts[0]['kills'] = $kills-$row['kills'];
$wksts[0]['deaths'] = $deaths-$row['deaths'];
if ($wksts[0]['deaths'] == 0) {$wksts[0]['kdratio'] = 99;}
else {$wksts[0]['kdratio'] = round($wksts[0]['kills'] / $wksts[0]['deaths'],2);}
$wksts[0]['timeplayed'] = formatTime($timeplayed-$row['timeplayed']);
$wksts[0]['score'] = $combatscore+$awardscore-$row['combatscore']-$row['awardscore'];
if ($$wksts[0]['timeplayed'] == 0) {$wksts[0]['scorepermin'] = 0;}
else {$wksts[0]['scorepermin'] = round($wksts[0]['score']*60/$wksts[0]['timeplayed'],2);}
$wksts[0]['position'] = $row['position'];

$numrows = mysql_num_rows($result);

for ($i=1; $i<$numrows; $i++) {
	$prevkills = $row['kills'];
	$prevdeaths = $row['deaths'];
	$prevtimeplayed = $row['timeplayed'];
	$prevscore = $row['combatscore']+$row['awardscore'];
	$row = mysql_fetch_array($result);
	$wksts[$i] = array();
	$wksts[$i]['kills'] = $prevkills - $row['kills'];
	$wksts[$i]['deaths'] = $prevdeaths - $row['deaths'];
	if ($wksts[$i]['deaths'] == 0) {$wksts[$i]['kdratio'] = 99;}
	else {$wksts[$i]['kdratio'] = round($wksts[$i]['kills'] / $wksts[$i]['deaths'],2);}
	$wksts[$i]['timeplayed'] = $prevtimeplayed - $row['timeplayed'];
	$wksts[$i]['score'] = $prevscore - $row['combatscore'] - $row['awardscore'];
	if ($$wksts[$i]['timeplayed'] == 0) {$wksts[$i]['scorepermin'] = 0;}
	else {$wksts[$i]['scorepermin'] = round($wksts[$i]['score']*60/$wksts[$i]['timeplayed'],2);}
	$wksts[$i]['position'] = $row['position'];
}

$rank = 0;
$ranktitle = "no rank";
$nextranktitle = "n/a";
$nextrankgoal = 0;
if (($handle = fopen("/var/www/bc2/rank.csv", "r")) !== FALSE) {
	while (($data = fgetcsv($handle, 50, ",")) !== FALSE) {
		if ($totalscore < $data[2]) {
			$nextrankgoal = $data[2];
			$nextranktitle = $data[1];
			break;
		}
		else {
			$rank++;
			$ranktitle = $data[1];
		}
	}
	fclose($handle);
}
echo "<div class='header'><h1>". $username . "</h1></div>";

echo "<div class='statArea'>";
echo "<table class='outer'><tr><td valign='top'>";
echo "<h2>Weekly Stats</h2>";
echo "<table class='statgrid standard'><tr><th></th><th>This week</th><th>Last Week</th><th>2 Weeks Ago</th><th>All Time</th></tr>";
echo "<tr><th>Kills</th><td>".$wksts[0]['kills']."</td><td>".$wksts[1]['kills']."</td><td>".$wksts[2]['kills']."</td><td>$kills</td></tr>";
echo "<tr><th>Deaths</th><td>".$wksts[0]['deaths']."</td><td>".$wksts[1]['deaths']."</td><td>".$wksts[2]['deaths']."</td><td>$deaths</td></tr>";
echo "<tr><th>KD Ratio</th><td>".$wksts[0]['kdratio']."</td><td>".$wksts[1]['kdratio']."</td><td>".$wksts[2]['kdratio']."</td><td>$kdratio</td></tr>";
echo "<tr><th>Time Played</th><td>".formatTime($wksts[0]['timeplayed'])."</td><td>".formatTime($wksts[1]['timeplayed'])."</td><td>".formatTime($wksts[2]['timeplayed'])."</td><td>".formatTime($timeplayed)."</td></tr>";
echo "<tr><th>Score</th><td>".$wksts[0]['score']."</td><td>".$wksts[1]['score']."</td><td>".$wksts[2]['score']."</td><td>$totalscore</td></tr>";
echo "<tr><th>Position</th><td>".$wksts[0]['position']."</td><td>".$wksts[1]['position']."</td><td>".$wksts[2]['position']."</td><td>$position</td></tr>";
echo "<tr><th>Score/Min</th><td>".$wksts[0]['scorepermin']."</td><td>".$wksts[1]['scorepermin']."</td><td>".$wksts[2]['scorepermin']."</td><td>$scorepermin</td></tr>";
echo "</table>";

echo "</td><td valign='top'>";

echo "<h2>Score</h2>";
echo "<table class='statgrid  standard'><tr><th>Assault Score</th><td>$assaultscore</td></tr><tr><th>Medic Score</th><td>$medicscore</td></tr><tr><th>Recon Score</th><td>$reconscore</td></tr><tr><th>Engineer Score</th><td>$engiscore</td></tr><tr><th>Vehicle Score</th><td>$vehiclescore</td></tr><tr><th>Combat Score</th><td>$combatscore</td></tr><tr><th>Award Score</th><td>$awardscore</td></tr><tr><th>Total Score</th><td>$totalscore</td></tr></table>";

echo "</td><td valign='top'>";

echo "<h2>Rank</h2>";
echo "<table class='statgrid standard'><tr><th>Rank</th><td>$rank</td><tr></tr><th>Rank title</th><td>$ranktitle</td><tr></tr><th>Next Rank Title</th><td>$nextranktitle</td><tr></tr><th>Score</th><td>$totalscore</td><tr></tr><th>Next Rank Goal</th><td>$nextrankgoal</td></tr></table>";

echo "</td></tr></table></div>";

//////////////////////// Stats for Guns, Gadgets, and Vehicles ///////////////////////////////////////////

echo "<ul id='tabs'>";
echo "<li><a href='#guns'>Guns</a></li>";
echo "<li><a href='#gadgets'>Gadgets</a></li>";
echo "<li><a href='#vehicles'>Vehicles</a></li>";
echo "</ul>";
echo "<div class='itemTabs' id='guns'>";
echo "<table class='statgrid itemstats'>";
echo "<tr><th>Assault</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"aek\")'>AEK 971</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"xm8\")'>XM8 Prototype</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"f2000\")'>F2000</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"stg\")'>Stg.77 AUG</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"an94\")'>AN-94</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m416\")'>M416</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m16\")'>M16</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m16s\")'>M16 Spectat</a></td>";
echo "</tr>";
echo "<tr><th>Medic</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"pkm\")'>PKM LMG</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m249\")'>M249 SAW</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"t88\")'>Type 88 LMG</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m60\")'>M60 LMG</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"xm8lmg\")'>XM8 LMG</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"mg36\")'>MG36</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"mg3\")'>MG3</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"mg3s\")'>MG3 Spectat</a></td>";
echo "</tr>";
echo "<tr><th>Engineer</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"9a91\")'>9A-91 Avtomat</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"scar\")'>Scar-L Carbine</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"xm8c\")'>XM8 Compact</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"aks\")'>AKS-74U</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"uzi\")'>UZI</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"pp\")'>PP-2000 Avtomat</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"ump\")'>UMP45</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"umps\")'>UMP45 Spectat</a></td>";
echo "</tr>";
echo "<tr><th>Recon</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m24\")'>M24 Sniper</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"t88s\")'>Type 88 Sniper</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"sv98\")'>SV98 Snaiperskaya</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"svu\")'>SVU Snaiperskaya Short</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"gol\")'>GOL Sniper Magnum</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"vss\")'>VSS Snaiperskaya Special</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m95\")'>M95 Sniper</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m95s\")'>M95 Sniper Spectat</a></td>";
echo "</tr>";
echo "<tr><th rowspan=2>All</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m9\")'>M9</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"870\")'>870 Combat</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"saiga\")'>SAIGA 20k Semi</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"mp433\")'>MP-433 GRACH</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m1911\")'>WWII M1911 .45</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m1a1\")'>WWII M1A1 Thompson</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"mp412\")'>MP-412 Rex</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m93r\")'>M93R Burst</a></td>";
echo "</tr>";
echo "<tr>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"spas\")'>SPAS-12 Combat</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m14\")'>M14</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"n2000\")'>Neostead 2000 Combat</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"g3\")'>G3</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"usas\")'>USAS-12 Auto</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gun\",\"m1\")'>M1 Garand</a></td>";
echo "<td></td><td></td>";
echo "</tr>";
echo "</table></div>";

echo "<div class='itemTabs' id='gadgets'>";
echo "<table class='statgrid itemstats'><tr><th>Assault</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"40g\")'>40mm Grenade</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"ammo\")'>Ammo</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"40sm\")'>40mm Smoke</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"40sh\")'>40mm Shotgun</a></td>";
echo "<td></td></tr><tr><th>Medic</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"medic\")'>Medic Kit</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"def\")'>Defibrillator</a></td>";
echo "<td></td><td></td><td></td></tr><tr><th>Engineer</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"rpg\")'>RPG-7 AT</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"repair\")'>Repair Tool</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"atm\")'>Anti-Tank Mine</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"carl\")'>M2 Carl Gustav</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"m136\")'>M136 AT4</a></td>";
echo "</tr><tr><th>Recon</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"c4\")'>C4</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"motion\")'>Motion Sensor</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"mort\")'>Mortar</a></td>";
echo "<td></td><td></td></tr><tr><th>All</th>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"kni\")'>Knife</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"nade\")'>Grenade</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"trac\")'>Tracer Gun</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"gadget\",\"bay\")'>M1 Bayonette</a></td>";
echo "<td></td></tr></table></div>";

echo "<div class='itemTabs' id='vehicles'>";
echo "<table class='statgrid itemstats'><tr><th>Light</td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"hmv\")'>HMMWV</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"vod\")'>Vodnik</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"cob\")'>Cobra</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"quad\")'>Quad Bike</a></td>";
echo "<td></td></tr><tr><th>Heavy</th>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"m1a2\")'>M1A2 Abrams</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"t90\")'>T90 MBT</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"m3a3\")'>M3A3 Bradley</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"bmd\")'>BMD-3 Bakhcha</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"bmda\")'>BMD-3 Bakhcha AA</a></td>";
echo "</tr><tr><th>Water</th>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"water\")'>Jet Ski</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"patrol\")'>Patrol Boat</a></td>";
echo "<td></td><td></td><td></td></tr><tr><th>Air</th>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"uh60\")'>UH-60 Transport</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"ah64\")'>AH-64 Apache</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"mi28\")'>MI-28 Havoc</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"mi24\")'>MI-24 Hind</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"uav\")'>UAV</a></td>";
echo "</tr><tr><th>Stationary</th>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"hmg1\")'>Heavy Machine Gun</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"hmg2\")'>Heavy Machine Gun</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"sat1\")'>Stationary AT</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"sat2\")'>Stationary AT</a></td>";
echo "<td><a href='javascript:showitemstats($persona, \"vehicle\",\"aag\")'>Anti-Air Gun</a></td>";
echo "</tr></table></div>";
echo "<div id='statbox' border=1></div>";

$assaultunlocks = array();
$medicunlocks = array();
$reconunlocks = array();
$engiunlocks = array();
$vehicleunlocks = array();
$assaultindex = 0;
$medicindex = 0;
$reconindex = 0;
$engiindex = 0;
$vehicleindex = 0;
$assaultset = 0;
$medicset = 0;
$reconset = 0;
$engiset = 0;
$vehicleset = 0;
$assaultprev = 0;
$medicprev = 0;
$reconprev = 0;
$engiprev = 0;
$vehicleprev = 0;
if (($handle = fopen("/var/www/bc2/unlocks.csv", "r")) !== FALSE) {
	while (($data = fgetcsv($handle, 100, ",")) !== FALSE) {
		if ($data[0] == "a") {
			$complete = 0;
			if ($assaultset) {$complete=2;}
			elseif ($assaultscore < $data[2]) {
				$assaultset = 1;
				$complete = 1;				
			}
			else {$assaultprev = $data[2];}
			$assaultunlocks[$assaultindex++] = array($data[1], $data[2], $complete);
		}
		if ($data[0] == "m") {
			$complete = 0;
			if ($medicset) {$complete=2;}
			elseif ($medicscore < $data[2]) {
				$medicset = 1;
				$complete = 1;				
			}
			else {$medicprev = $data[2];}
			$medicunlocks[$medicindex++] = array($data[1], $data[2], $complete);
		}
		if ($data[0] == "r") {
			$complete = 0;
			if ($reconset) {$complete=2;}
			elseif ($reconscore < $data[2]) {
				$reconset = 1;
				$complete = 1;				
			}
			else {$reconprev = $data[2];}
			$reconunlocks[$reconindex++] = array($data[1], $data[2], $complete);
		}
		if ($data[0] == "e") {
			$complete = 0;
			if ($engiset) {$complete=2;}
			elseif ($engiscore < $data[2]) {
				$engiset = 1;
				$complete = 1;				
			}
			else {$engiprev = $data[2];}
			$engiunlocks[$engiindex++] = array($data[1], $data[2], $complete);
		}
		if ($data[0] == "v") {
			$complete = 0;
			if ($vehicleset) {$complete=2;}
			elseif ($vehiclescore < $data[2]) {
				$vehicleset = 1;
				$complete = 1;				
			}
			else {$vehicleprev = $data[2];}
			$vehicleunlocks[$vehicleindex++] = array($data[1], $data[2], $complete);
		}
	}
	fclose($handle);
}

function printunlocks($unlocks, $score, $prev, $title) {
	echo "<td valign='top'><table class='statgrid standard'><tr><th style='height: 50px'>$title</th><th>Status</th></tr>";
	foreach ($unlocks as $row) {
		if ($row[2] == 0) {$text = "<img src='img/checkmark.png' />";}
		elseif ($row[2] == 1) {$text = ($score-$prev) . "/" . ($row[1]-$prev);}
		else {$text="";}
		echo "<tr><td>".$row[0]."</td><td>$text</td></tr>";
	}
	echo "</table></td>";
}

echo "<div class='statarea'>";
echo "<h2>Unlocks</h2>";
echo "<table class='standard'><tr>";
printunlocks($assaultunlocks, $assaultscore, $assaultprev, "Assault Unlocks");
printunlocks($medicunlocks, $medicscore, $medicprev, "Medic Unlocks");
printunlocks($reconunlocks, $reconscore, $reconprev, "Recon Unlocks");
printunlocks($engiunlocks, $engiscore, $engiprev, "Engineer Unlocks");
printunlocks($vehicleunlocks, $vehiclescore, $vehicleprev, "Vehicle Unlocks");
echo "</tr></table></div>";
echo "</div></body></html>";
?>
