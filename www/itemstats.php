<?php

include("connect.php");

$categoryshort = array(
	"kills" => "_k",
	"shotsfired" => "_sf",
	"shotshit" => "_sh",
	"time" => "_t",
	"heals" => "_h",
	"resupplies" => "_r",
	"revives" => "_r",
	"lock" => "_l");

$gadgets = array(
	"40g" => array("kills", "shotsfired", "shotshit", "lock"),
	"ammo" => array("resupplies", "lock"),
	"40sm" => array("shotsfired", "lock"),
	"40sh" => array("kills", "shotsfired", "shotshit", "lock"),
	"medic" => array("heals", "lock"),
	"def" => array("kills", "revives", "lock"),
	"rpg" => array("kills", "shotsfired", "shotshit", "lock"),
	"repair" => array("kills", "time", "lock"),
	"atm" => array("kills", "shotsfired", "shotshit", "lock"),
	"carl" => array("kills", "shotsfired", "shotshit", "lock"),
	"m136" => array("kills", "shotsfired", "shotshit", "lock"),
	"c4" => array("kills", "time", "lock"),
	"motion" => array("shotsfired", "time", "lock"),
	"mort" => array("kills", "shotsfired", "shotshit", "lock"),
	"kni" => array("kills", "time", "lock"),
	"nade" => array("kills", "time", "lock"),
	"trac" => array("shotsfired", "shotshit", "lock"),
	"bay" => array("kills", "lock"));

$name = $_GET['name'];
$table = "stats";
$categories;
$values;
$numvalues=0;
if ($_GET['type'] == "gun") {
	$numvalues = 5;
	$categories = array("kills", "shotsfired", "shotshit", "time", "lock");
	$columns = array($name."_k", $name."_sf", $name."_sh", $name."_t", $name."_l");
	
	$sql = "SELECT ".$columns[0].",".$columns[1].",".$columns[2].",".$columns[3].",".$columns[4]." FROM gunstats WHERE persona = " . $_GET['persona'];
	$result = mysql_query($sql);
	$row = mysql_fetch_array($result);
	
	for ($i=0; $i<$numvalues; $i++) {
		$values[$i] = $row[$columns[$i]];
	}
}
else if ($_GET['type'] == "gadget") {
	$categories = $gadgets[$name];
	$numvalues = count($categories);
	$columnstring = "";
	for ($i=0; $i<$numvalues; $i++) {
		$columns[$i] = $name.$categoryshort[$categories[$i]];
		$columnstring = $columnstring.$columns[$i].",";
	}
	$columnstring = rtrim($columnstring, ",");
	$sql = "SELECT ".$columnstring." FROM gadgetstats WHERE persona = " . $_GET['persona'];
	
	$result = mysql_query($sql);
	$row = mysql_fetch_array($result);
	
	for ($i=0; $i<$numvalues; $i++) {
		$values[$i] = $row[$columns[$i]];
	}
}
else if ($_GET['type'] == "vehicle") {
	if ($name=='hmg1'||$name=='hmg2'||$name=='sat1'||$name=='sat2'||$name=='aag') {
		$numvalues = 2;
		$categories = array("kills", "time");
		$columns = array($name."_k", $name."_t");
		$columnstring = $columns[0].",".$columns[1].",";
	}
	else {
		$numvalues = 4;
		$categories = array("kills", "roadkills", "distance", "time");
		$columns = array($name."_k", $name."_r",$name."_d",$name."_t");
		$columnstring = $columns[0].",".$columns[1].",".$columns[2].",".$columns[3].",";
	}
	$columnstring = rtrim($columnstring, ",");
	$sql = "SELECT ".$columnstring." FROM vehiclestats WHERE persona = " . $_GET['persona'];
	$result = mysql_query($sql);
	$row = mysql_fetch_array($result);
	
	for ($i=0; $i<$numvalues; $i++) {
		$values[$i] = $row[$columns[$i]];
	}
}

echo "<" . $table . ">\n";
for ($i=0; $i<$numvalues; $i++) {
	echo "<" . $categories[$i] . ">" . $values[$i] . "</" . $categories[$i] . ">\n";
}
echo "<type>" . $_GET['type'] . "</type>\n";
echo "</" . $table . ">\n";
?>
