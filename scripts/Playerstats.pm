package Playerstats;

use strict;
use WWW::Mechanize;
use HTML::TokeParser;
use Itemstat;
use DBI;

my $host = "localhost";
my $db = "sarevok";
my $user = "sarevok";
my $pw = "JohnMayL1v3s";

######################### helper functions ##############################

sub find_text {
  my($stream, $starttag, $text) = @_;
  
  my $found = 0;
  while (!$found) {
    my $tag = $stream->get_tag($starttag);
    my $testtext = $stream->get_text();
    if (!$tag || $testtext eq $text) {
      $found = 1;
    }
  }
}

sub find_class {
  my($stream, $starttag, $class) = @_;

  my $found = 0;
  while (!$found) {
    my $tag = $stream->get_tag($starttag);
    if (!$tag || ($tag->[1]{class} && $tag->[1]{class} eq $class)) {
      $found = 1;
    }
  }
}

sub getItemStats {
	my ($count, $stream) = @_;

   my @allstats;
	for (my $i=0; $i<$count; $i++) {
		my $itemstats = new Itemstat();
		$stream->get_tag("a");

		my $tag = $stream->get_tag("img");
		if ($tag->[1]{class} && $tag->[1]{class} eq "locked"){$itemstats->lock();}
		else {
			$stream->get_tag("span");
			my $statdata = $stream->get_text();
			my @splitdata = split(/%3B%/, $statdata);
	  
			foreach (@splitdata) {
				if (/%22(\d+).\d+%22$/) {$itemstats->addStat($1);}
			}	    
		}
		push(@allstats, $itemstats);
	}
	return @allstats;
}

####################################
## Pass the age verification page
####################################
sub passAgeGate {
	my ($agent) = @_;

	my $response = $agent->get("http://badcompany2.ea.com/leaderboards");
	die "Problem connecting to EA" unless ($response->is_success);

	$agent->form_number(1);
	$agent->field("age", "20");
	$agent->click();
}

###########################################
## Check if player exists on EA site 
## if so add to database and return persona.
## Otherwise return -1
############################################
sub newPlayer {
	my ($agent, $username, $platform) = @_;

	$agent->get("http://www.badcompany2.ea.com/leaderboards/ajax?platform=" . $platform . "&sort=score&start=1&search=" . $username);
	my $text = $agent->content();

	my $dbh = DBI->connect( "dbi:mysql:$db", $user, $pw, { 'PrintError' => 1, 'RaiseError' => 1 } );

	if ($text =~ /No such soldier found/ || $text !~ /persona=(\d{9})/) {
		#If the soldier doesn't exists, mark and keep in pending users for an hour (deletependingusers.pl will delete)
		my $sql = "UPDATE pendingusers SET nonexistant=1 WHERE username='".$username."'";
		my $sql_handle=$dbh->prepare($sql);
		$sql_handle->execute();
		print "No such soldier: $username\n";
		return -1;
	}
	#if ($text =~ /stats are being updated/) {
	#	print "Stats are being updated\n";
	#	return -1
	#}
	my $persona = $1;

	my $currenttime = time;

	my $platformnum;
	if ($platform eq "pc") {$platformnum = 1;}
	elsif ($platform eq "360") {$platformnum = 2;}
	elsif ($platform eq "ps3") {$platformnum = 3;}

	my $sql = "INSERT INTO bc2users VALUES ($persona, '$username', $platformnum, $currenttime) ON DUPLICATE KEY UPDATE lastupdate=$currenttime";
	my $sql_handle=$dbh->prepare($sql);
	$sql_handle->execute();
	print "Added user to bc2users: $username, $persona \n";

	$sql = "DELETE FROM pendingusers WHERE username='".$username."'";
	$sql_handle=$dbh->prepare($sql);
	$sql_handle->execute();
	print "Removed from pendingusers: $username\n";

	return $persona;
}

##############################
## Parse stats for player
##############################
sub updatePlayerStats {
my ($agent, $persona, $platform, $weekly) = @_;

$agent->get("http://www.badcompany2.ea.com/stats?persona=" . $persona . "&platform=" . $platform);

my $stream = HTML::TokeParser->new(\$agent->{content});

find_class($stream, "div", "stat-fields");
find_text($stream, "span", "POSITION:");
$stream->get_tag("span");
$stream->get_tag("/span");
my $position = $stream->get_text();
$position =~ s/^\s+//;
$position =~ s/\s+$//;
if ($position !~ /^\d+$/) {$position = 10001;}
find_text($stream, "span", "Time played MP");

$stream->get_tag("span");
my $timestring = $stream->get_text();
my $timeplayed = 0;
if ($timestring =~ /(\d*)d (\d*)h (\d*)m.*/) {
	$timeplayed += $1 * 86400;
	$timeplayed += $2 * 3600;
	$timeplayed += $3 * 60;
}
print("Time played: " . $timeplayed . "\n");

find_class($stream, "span", "value");
my $scoremin = $stream->get_text();

find_class($stream, "span", "value");
my $kd = $stream->get_text();

find_class($stream, "span", "value");
my $totalscore = $stream->get_text();
$totalscore =~ tr/ //d;

find_class($stream, "div", "rank-info");
my $tag = $stream->get_tag("img");
my $imgsrc = $tag->[1]{src};
my $rank = 1;
if ($imgsrc){
	if ($imgsrc =~ /.*R0(\d{2}).{4}$/) {$rank = $1;}
}

my $nextrankprog = 0;
my $nextrankgoal = 0;
if ($rank ne 50) {
  find_class($stream, "div", "rank-score");
  my @temp = split(/\//, $stream->get_text());
  $nextrankprog = $temp[0];
  $nextrankgoal = $temp[1];
  $nextrankprog =~ tr/ //d;
  $nextrankgoal =~ tr/ //d;
}

find_class($stream, "div", "stats-block stats-block-right");

find_class($stream, "span", "value");
my $assaultscore = $stream->get_text();
$assaultscore =~ tr/\+ //d;

find_class($stream, "span", "value");
my $medicscore = $stream->get_text();
$medicscore =~ tr/\+ //d;

find_class($stream, "span", "value");
my $reconscore = $stream->get_text();
$reconscore =~ tr/\+ //d;

find_class($stream, "span", "value");
my $engineerscore = $stream->get_text();
$engineerscore =~ tr/\+ //d;

find_class($stream, "span", "value");
my $vehiclescore = $stream->get_text();
$vehiclescore =~ tr/\+ //d;

find_class($stream, "span", "value");
my $combatscore = $stream->get_text();
$combatscore =~ tr/\= //d;

find_class($stream, "span", "value");
my $awardscore = $stream->get_text();
$awardscore =~ tr/\+ //d;

find_class($stream, "span", "value");

find_class($stream, "span", "value");
my $kills = $stream->get_text();
$kills =~ tr/ //d;

find_class($stream, "span", "value");
my $deaths = $stream->get_text();
$deaths =~ tr/ //d;

my (@gunstats, @gadgetstats, @vehiclestats);
########################### weapon stats #############################
print "loading guns\n";

$agent->get("http://www.badcompany2.ea.com/weaponsgadgets/ajax?platform=" . $platform . "&persona=" . $persona . "&cat=weapons");
$stream = HTML::TokeParser->new(\$agent->{content});

@gunstats = getItemStats(46, $stream);


########################## gadgets ##################################

print "loading gadgets\n";

$agent->get("http://www.badcompany2.ea.com/weaponsgadgets/ajax?platform=" . $platform . "&persona=" . $persona . "&cat=gadgets");
$stream = HTML::TokeParser->new(\$agent->{content});

@gadgetstats = getItemStats(18, $stream);

########################## vehicles ##################################

print "loading vehicles\n";

$agent->get("http://www.badcompany2.ea.com/weaponsgadgets/ajax?platform=" . $platform . "&persona=" . $persona . "&cat=vehicles");
$stream = HTML::TokeParser->new(\$agent->{content});

@vehiclestats = getItemStats(21, $stream);

######################### Mysql ##############################

print "Storing in mysql: Persona: $persona, Position: $position, Time played: $timeplayed, Kills: $kills, Deaths: $deaths, Assaultscore $assaultscore, Reconscore: $reconscore, Medicscore: $medicscore, Engineerscore: $engineerscore, Vehicle score: $vehiclescore, Combatscore: $combatscore, Awardscore: $awardscore\n";

my $currenttime = time;
my ($sql, $sql_handle);

my $dbh = DBI->connect( "dbi:mysql:$db", $user, $pw, { 'PrintError' => 1, 'RaiseError' => 1 } );

$sql = "INSERT INTO mainstats VALUES ($persona, $currenttime, $position, $timeplayed, $kills, $deaths, $assaultscore, $medicscore, $reconscore, $engineerscore, $vehiclescore, $combatscore, $awardscore) ON DUPLICATE KEY UPDATE persona=values(persona), time=values(time), position=values(position), kills=values(kills), deaths=values(deaths), assaultscore=values(assaultscore), medicscore=values(medicscore), reconscore=values(reconscore), engiscore=values(engiscore), vehiclescore=values(vehiclescore), combatscore=values(combatscore), awardscore=values(awardscore)";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

if ($weekly) {
	$sql = "INSERT INTO weeklystats VALUES ($persona, $currenttime, $position, $timeplayed, $kills, $deaths, $assaultscore, 
		$medicscore, $reconscore, $engineerscore, $vehiclescore, $combatscore, $awardscore)";

	$sql_handle=$dbh->prepare($sql);
	$sql_handle->execute();
}



$sql = "INSERT INTO gunstats VALUES ($persona, $currenttime, ".$gunstats[0]->getStat(0).", ".$gunstats[0]->getStat(1).", ".$gunstats[0]->getStat(2).", ".$gunstats[0]->getStat(3).", ".$gunstats[0]->isLocked().", ".$gunstats[1]->getStat(0).", ".$gunstats[1]->getStat(1).", ".$gunstats[1]->getStat(2).", ".$gunstats[1]->getStat(3).", ".$gunstats[1]->isLocked().", ".$gunstats[2]->getStat(0).", ".$gunstats[2]->getStat(1).", ".$gunstats[2]->getStat(2).", ".$gunstats[2]->getStat(3).", ".$gunstats[2]->isLocked().", ".$gunstats[3]->getStat(0).", ".$gunstats[3]->getStat(1).", ".$gunstats[3]->getStat(2).", ".$gunstats[3]->getStat(3).", ".$gunstats[3]->isLocked().", ".$gunstats[4]->getStat(0).", ".$gunstats[4]->getStat(1).", ".$gunstats[4]->getStat(2).", ".$gunstats[4]->getStat(3).", ".$gunstats[4]->isLocked().", ".$gunstats[5]->getStat(0).", ".$gunstats[5]->getStat(1).", ".$gunstats[5]->getStat(2).", ".$gunstats[5]->getStat(3).", ".$gunstats[5]->isLocked().", ".$gunstats[6]->getStat(0).", ".$gunstats[6]->getStat(1).", ".$gunstats[6]->getStat(2).", ".$gunstats[6]->getStat(3).", ".$gunstats[6]->isLocked().", ".$gunstats[7]->getStat(0).", ".$gunstats[7]->getStat(1).", ".$gunstats[7]->getStat(2).", ".$gunstats[7]->getStat(3).", ".$gunstats[7]->isLocked().", ".$gunstats[8]->getStat(0).", ".$gunstats[8]->getStat(1).", ".$gunstats[8]->getStat(2).", ".$gunstats[8]->getStat(3).", ".$gunstats[8]->isLocked().", ".$gunstats[9]->getStat(0).", ".$gunstats[9]->getStat(1).", ".$gunstats[9]->getStat(2).", ".$gunstats[9]->getStat(3).", ".$gunstats[9]->isLocked().", ".$gunstats[10]->getStat(0).", ".$gunstats[10]->getStat(1).", ".$gunstats[10]->getStat(2).", ".$gunstats[10]->getStat(3).", ".$gunstats[10]->isLocked().", ".$gunstats[11]->getStat(0).", ".$gunstats[11]->getStat(1).", ".$gunstats[11]->getStat(2).", ".$gunstats[11]->getStat(3).", ".$gunstats[11]->isLocked().", ".$gunstats[12]->getStat(0).", ".$gunstats[12]->getStat(1).", ".$gunstats[12]->getStat(2).", ".$gunstats[12]->getStat(3).", ".$gunstats[12]->isLocked().", ".$gunstats[13]->getStat(0).", ".$gunstats[13]->getStat(1).", ".$gunstats[13]->getStat(2).", ".$gunstats[13]->getStat(3).", ".$gunstats[13]->isLocked().", ".$gunstats[14]->getStat(0).", ".$gunstats[14]->getStat(1).", ".$gunstats[14]->getStat(2).", ".$gunstats[14]->getStat(3).", ".$gunstats[14]->isLocked().", ".$gunstats[15]->getStat(0).", ".$gunstats[15]->getStat(1).", ".$gunstats[15]->getStat(2).", ".$gunstats[15]->getStat(3).", ".$gunstats[15]->isLocked().", ".$gunstats[16]->getStat(0).", ".$gunstats[16]->getStat(1).", ".$gunstats[16]->getStat(2).", ".$gunstats[16]->getStat(3).", ".$gunstats[16]->isLocked().", ".$gunstats[17]->getStat(0).", ".$gunstats[17]->getStat(1).", ".$gunstats[17]->getStat(2).", ".$gunstats[17]->getStat(3).", ".$gunstats[17]->isLocked().", ".$gunstats[18]->getStat(0).", ".$gunstats[18]->getStat(1).", ".$gunstats[18]->getStat(2).", ".$gunstats[18]->getStat(3).", ".$gunstats[18]->isLocked().", ".$gunstats[19]->getStat(0).", ".$gunstats[19]->getStat(1).", ".$gunstats[19]->getStat(2).", ".$gunstats[19]->getStat(3).", ".$gunstats[19]->isLocked().", ".$gunstats[20]->getStat(0).", ".$gunstats[20]->getStat(1).", ".$gunstats[20]->getStat(2).", ".$gunstats[20]->getStat(3).", ".$gunstats[20]->isLocked().", ".$gunstats[21]->getStat(0).", ".$gunstats[21]->getStat(1).", ".$gunstats[21]->getStat(2).", ".$gunstats[21]->getStat(3).", ".$gunstats[21]->isLocked().", ".$gunstats[22]->getStat(0).", ".$gunstats[22]->getStat(1).", ".$gunstats[22]->getStat(2).", ".$gunstats[22]->getStat(3).", ".$gunstats[22]->isLocked().", ".$gunstats[23]->getStat(0).", ".$gunstats[23]->getStat(1).", ".$gunstats[23]->getStat(2).", ".$gunstats[23]->getStat(3).", ".$gunstats[23]->isLocked().", ".$gunstats[24]->getStat(0).", ".$gunstats[24]->getStat(1).", ".$gunstats[24]->getStat(2).", ".$gunstats[24]->getStat(3).", ".$gunstats[24]->isLocked().", ".$gunstats[25]->getStat(0).", ".$gunstats[25]->getStat(1).", ".$gunstats[25]->getStat(2).", ".$gunstats[25]->getStat(3).", ".$gunstats[25]->isLocked().", ".$gunstats[26]->getStat(0).", ".$gunstats[26]->getStat(1).", ".$gunstats[26]->getStat(2).", ".$gunstats[26]->getStat(3).", ".$gunstats[26]->isLocked().", ".$gunstats[27]->getStat(0).", ".$gunstats[27]->getStat(1).", ".$gunstats[27]->getStat(2).", ".$gunstats[27]->getStat(3).", ".$gunstats[27]->isLocked().", ".$gunstats[28]->getStat(0).", ".$gunstats[28]->getStat(1).", ".$gunstats[28]->getStat(2).", ".$gunstats[28]->getStat(3).", ".$gunstats[28]->isLocked().", ".$gunstats[29]->getStat(0).", ".$gunstats[29]->getStat(1).", ".$gunstats[29]->getStat(2).", ".$gunstats[29]->getStat(3).", ".$gunstats[29]->isLocked().", ".$gunstats[30]->getStat(0).", ".$gunstats[30]->getStat(1).", ".$gunstats[30]->getStat(2).", ".$gunstats[30]->getStat(3).", ".$gunstats[30]->isLocked().", ".$gunstats[31]->getStat(0).", ".$gunstats[31]->getStat(1).", ".$gunstats[31]->getStat(2).", ".$gunstats[31]->getStat(3).", ".$gunstats[31]->isLocked().", ".$gunstats[32]->getStat(0).", ".$gunstats[32]->getStat(1).", ".$gunstats[32]->getStat(2).", ".$gunstats[32]->getStat(3).", ".$gunstats[32]->isLocked().", ".$gunstats[33]->getStat(0).", ".$gunstats[33]->getStat(1).", ".$gunstats[33]->getStat(2).", ".$gunstats[33]->getStat(3).", ".$gunstats[33]->isLocked().", ".$gunstats[34]->getStat(0).", ".$gunstats[34]->getStat(1).", ".$gunstats[34]->getStat(2).", ".$gunstats[34]->getStat(3).", ".$gunstats[34]->isLocked().", ".$gunstats[35]->getStat(0).", ".$gunstats[35]->getStat(1).", ".$gunstats[35]->getStat(2).", ".$gunstats[35]->getStat(3).", ".$gunstats[35]->isLocked().", ".$gunstats[36]->getStat(0).", ".$gunstats[36]->getStat(1).", ".$gunstats[36]->getStat(2).", ".$gunstats[36]->getStat(3).", ".$gunstats[36]->isLocked().", ".$gunstats[37]->getStat(0).", ".$gunstats[37]->getStat(1).", ".$gunstats[37]->getStat(2).", ".$gunstats[37]->getStat(3).", ".$gunstats[37]->isLocked().", ".$gunstats[38]->getStat(0).", ".$gunstats[38]->getStat(1).", ".$gunstats[38]->getStat(2).", ".$gunstats[38]->getStat(3).", ".$gunstats[38]->isLocked().", ".$gunstats[39]->getStat(0).", ".$gunstats[39]->getStat(1).", ".$gunstats[39]->getStat(2).", ".$gunstats[39]->getStat(3).", ".$gunstats[39]->isLocked().", ".$gunstats[40]->getStat(0).", ".$gunstats[40]->getStat(1).", ".$gunstats[40]->getStat(2).", ".$gunstats[40]->getStat(3).", ".$gunstats[40]->isLocked().", ".$gunstats[41]->getStat(0).", ".$gunstats[41]->getStat(1).", ".$gunstats[41]->getStat(2).", ".$gunstats[41]->getStat(3).", ".$gunstats[41]->isLocked().", ".$gunstats[42]->getStat(0).", ".$gunstats[42]->getStat(1).", ".$gunstats[42]->getStat(2).", ".$gunstats[42]->getStat(3).", ".$gunstats[42]->isLocked().", ".$gunstats[43]->getStat(0).", ".$gunstats[43]->getStat(1).", ".$gunstats[43]->getStat(2).", ".$gunstats[43]->getStat(3).", ".$gunstats[43]->isLocked().", ".$gunstats[44]->getStat(0).", ".$gunstats[44]->getStat(1).", ".$gunstats[44]->getStat(2).", ".$gunstats[44]->getStat(3).", ".$gunstats[44]->isLocked().", ".$gunstats[45]->getStat(0).", ".$gunstats[45]->getStat(1).", ".$gunstats[45]->getStat(2).", ".$gunstats[45]->getStat(3).", ".$gunstats[45]->isLocked().
") ON DUPLICATE KEY UPDATE time=values(time), aek_k=values(aek_k), aek_sf=values(aek_sf), aek_sh=values(aek_sh), aek_t=values(aek_t), aek_l=values(aek_l), xm8_k=values(xm8_k), xm8_sf=values(xm8_sf), xm8_sh=values(xm8_sh), xm8_t=values(xm8_t), xm8_l=values(xm8_l), f2000_k=values(f2000_k), f2000_sf=values(f2000_sf), f2000_sh=values(f2000_sh), f2000_t=values(f2000_t), f2000_l=values(f2000_l), stg_k=values(stg_k), stg_sf=values(stg_sf), stg_sh=values(stg_sh), stg_t=values(stg_t), stg_l=values(stg_l), an94_k=values(an94_k), an94_sf=values(an94_sf), an94_sh=values(an94_sh), an94_t=values(an94_t), an94_l=values(an94_l), m416_k=values(m416_k), m416_sf=values(m416_sf), m416_sh=values(m416_sh), m416_t=values(m416_t), m416_l=values(m416_l), m16_k=values(m16_k), m16_sf=values(m16_sf), m16_sh=values(m16_sh), m16_t=values(m16_t), m16_l=values(m16_l), pkm_k=values(pkm_k), pkm_sf=values(pkm_sf), pkm_sh=values(pkm_sh), pkm_t=values(pkm_t), pkm_l=values(pkm_l), m249_k=values(m249_k), m249_sf=values(m249_sf), m249_sh=values(m249_sh), m249_t=values(m249_t), m249_l=values(m249_l), t88_k=values(t88_k), t88_sf=values(t88_sf), t88_sh=values(t88_sh), t88_t=values(t88_t), t88_l=values(t88_l), m60_k=values(m60_k), m60_sf=values(m60_sf), m60_sh=values(m60_sh), m60_t=values(m60_t), m60_l=values(m60_l), xm8lmg_k=values(xm8lmg_k), xm8lmg_sf=values(xm8lmg_sf), xm8lmg_sh=values(xm8lmg_sh), xm8lmg_t=values(xm8lmg_t), xm8lmg_l=values(xm8lmg_l), mg36_k=values(mg36_k), mg36_sf=values(mg36_sf), mg36_sh=values(mg36_sh), mg36_t=values(mg36_t), mg36_l=values(mg36_l), mg3_k=values(mg3_k), mg3_sf=values(mg3_sf), mg3_sh=values(mg3_sh), mg3_t=values(mg3_t), mg3_l=values(mg3_l), mg3s_k=values(mg3s_k), mg3s_sf=values(mg3s_sf), mg3s_sh=values(mg3s_sh), mg3s_t=values(mg3s_t), mg3s_l=values(mg3s_l), 9a91_k=values(9a91_k), 9a91_sf=values(9a91_sf), 9a91_sh=values(9a91_sh), 9a91_t=values(9a91_t), 9a91_l=values(9a91_l), scar_k=values(scar_k), scar_sf=values(scar_sf), scar_sh=values(scar_sh), scar_t=values(scar_t), scar_l=values(scar_l), xm8c_k=values(xm8c_k), xm8c_sf=values(xm8c_sf), xm8c_sh=values(xm8c_sh), xm8c_t=values(xm8c_t), xm8c_l=values(xm8c_l), aks_k=values(aks_k), aks_sf=values(aks_sf), aks_sh=values(aks_sh), aks_t=values(aks_t), aks_l=values(aks_l), uzi_k=values(uzi_k), uzi_sf=values(uzi_sf), uzi_sh=values(uzi_sh), uzi_t=values(uzi_t), uzi_l=values(uzi_l), pp_k=values(pp_k), pp_sf=values(pp_sf), pp_sh=values(pp_sh), pp_t=values(pp_t), pp_l=values(pp_l), ump_k=values(ump_k), ump_sf=values(ump_sf), ump_sh=values(ump_sh), ump_t=values(ump_t), ump_l=values(ump_l), umps_k=values(umps_k), umps_sf=values(umps_sf), umps_sh=values(umps_sh), umps_t=values(umps_t), umps_l=values(umps_l), m24_k=values(m24_k), m24_sf=values(m24_sf), m24_sh=values(m24_sh), m24_t=values(m24_t), m24_l=values(m24_l), t88s_k=values(t88s_k), t88s_sf=values(t88s_sf), t88s_sh=values(t88s_sh), t88s_t=values(t88s_t), t88s_l=values(t88s_l), sv98_k=values(sv98_k), sv98_sf=values(sv98_sf), sv98_sh=values(sv98_sh), sv98_t=values(sv98_t), sv98_l=values(sv98_l), svu_k=values(svu_k), svu_sf=values(svu_sf), svu_sh=values(svu_sh), svu_t=values(svu_t), svu_l=values(svu_l), gol_k=values(gol_k), gol_sf=values(gol_sf), gol_sh=values(gol_sh), gol_t=values(gol_t), gol_l=values(gol_l), vss_k=values(vss_k), vss_sf=values(vss_sf), vss_sh=values(vss_sh), vss_t=values(vss_t), vss_l=values(vss_l), m95_k=values(m95_k), m95_sf=values(m95_sf), m95_sh=values(m95_sh), m95_t=values(m95_t), m95_l=values(m95_l), m95s_k=values(m95s_k), m95s_sf=values(m95s_sf), m95s_sh=values(m95s_sh), m95s_t=values(m95s_t), m95s_l=values(m95s_l), m9_k=values(m9_k), m9_sf=values(m9_sf), m9_sh=values(m9_sh), m9_t=values(m9_t), m9_l=values(m9_l), 870_k=values(870_k), 870_sf=values(870_sf), 870_sh=values(870_sh), 870_t=values(870_t), 870_l=values(870_l), saiga_k=values(saiga_k), saiga_sf=values(saiga_sf), saiga_sh=values(saiga_sh), saiga_t=values(saiga_t), saiga_l=values(saiga_l), mp433_k=values(mp433_k), mp433_sf=values(mp433_sf), mp433_sh=values(mp433_sh), mp433_t=values(mp433_t), mp433_l=values(mp433_l), m1911_k=values(m1911_k), m1911_sf=values(m1911_sf), m1911_sh=values(m1911_sh), m1911_t=values(m1911_t), m1911_l=values(m1911_l), m1a1_k=values(m1a1_k), m1a1_sf=values(m1a1_sf), m1a1_sh=values(m1a1_sh), m1a1_t=values(m1a1_t), m1a1_l=values(m1a1_l), mp412_k=values(mp412_k), mp412_sf=values(mp412_sf), mp412_sh=values(mp412_sh), mp412_t=values(mp412_t), mp412_l=values(mp412_l), m93r_k=values(m93r_k), m93r_sf=values(m93r_sf), m93r_sh=values(m93r_sh), m93r_t=values(m93r_t), m93r_l=values(m93r_l), spas_k=values(spas_k), spas_sf=values(spas_sf), spas_sh=values(spas_sh), spas_t=values(spas_t), spas_l=values(spas_l), m14_k=values(m14_k), m14_sf=values(m14_sf), m14_sh=values(m14_sh), m14_t=values(m14_t), m14_l=values(m14_l), n2000_k=values(n2000_k), n2000_sf=values(n2000_sf), n2000_sh=values(n2000_sh), n2000_t=values(n2000_t), n2000_l=values(n2000_l), g3_k=values(g3_k), g3_sf=values(g3_sf), g3_sh=values(g3_sh), g3_t=values(g3_t), g3_l=values(g3_l), usas_k=values(usas_k), usas_sf=values(usas_sf), usas_sh=values(usas_sh), usas_t=values(usas_t), usas_l=values(usas_l), m1_k=values(m1_k), m1_sf=values(m1_sf), m1_sh=values(m1_sh), m1_t=values(m1_t), m1_l=values(m1_l)";


$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

$sql = "INSERT INTO gadgetstats VALUES ($persona, $currenttime, ".$gadgetstats[0]->getStat(0).", ".$gadgetstats[0]->getStat(1).", ".$gadgetstats[0]->getStat(2).", ".$gadgetstats[0]->isLocked().", ".$gadgetstats[1]->getStat(0).", ".$gadgetstats[1]->isLocked().", ".$gadgetstats[2]->getStat(0).", ".$gadgetstats[2]->isLocked().", ".$gadgetstats[3]->getStat(0).", ".$gadgetstats[3]->getStat(1).", ".$gadgetstats[3]->getStat(2).", ".$gadgetstats[3]->isLocked().", ".$gadgetstats[4]->getStat(0).", ".$gadgetstats[4]->isLocked().", ".$gadgetstats[5]->getStat(0).", ".$gadgetstats[5]->getStat(1).", ".$gadgetstats[5]->isLocked().", ".$gadgetstats[6]->getStat(0).", ".$gadgetstats[6]->getStat(1).", ".$gadgetstats[6]->getStat(2).", ".$gadgetstats[6]->isLocked().", ".$gadgetstats[7]->getStat(0).", ".$gadgetstats[7]->getStat(1).", ".$gadgetstats[7]->isLocked().", ".$gadgetstats[8]->getStat(0).", ".$gadgetstats[8]->getStat(1).", ".$gadgetstats[8]->getStat(2).", ".$gadgetstats[8]->isLocked().", ".$gadgetstats[9]->getStat(0).", ".$gadgetstats[9]->getStat(1).", ".$gadgetstats[9]->getStat(2).", ".$gadgetstats[9]->isLocked().", ".$gadgetstats[10]->getStat(0).", ".$gadgetstats[10]->getStat(1).", ".$gadgetstats[10]->getStat(2).", ".$gadgetstats[10]->isLocked().", ".$gadgetstats[11]->getStat(0).", ".$gadgetstats[11]->getStat(1).", ".$gadgetstats[11]->isLocked().", ".$gadgetstats[12]->getStat(0).", ".$gadgetstats[12]->getStat(1).", ".$gadgetstats[12]->isLocked().", ".$gadgetstats[13]->getStat(0).", ".$gadgetstats[13]->getStat(1).", ".$gadgetstats[13]->getStat(2).", ".$gadgetstats[13]->isLocked().", ".$gadgetstats[14]->getStat(0).", ".$gadgetstats[14]->getStat(1).", ".$gadgetstats[14]->isLocked().", ".$gadgetstats[15]->getStat(0).", ".$gadgetstats[15]->getStat(1).", ".$gadgetstats[15]->isLocked().", ".$gadgetstats[16]->getStat(0).", ".$gadgetstats[16]->getStat(1).", ".$gadgetstats[16]->isLocked().", ".$gadgetstats[17]->getStat(0).", ".$gadgetstats[17]->isLocked().
") ON DUPLICATE KEY UPDATE time=values(time), 40g_k=values(40g_k), 40g_sf=values(40g_sf), 40g_sh=values(40g_sh), 40g_l=values(40g_l), ammo_r=values(ammo_r), ammo_l=values(ammo_l), 40sm_sf=values(40sm_sf), 40sm_l=values(40sm_l), 40sh_k=values(40sh_k), 40sh_sf=values(40sh_sf), 40sh_sh=values(40sh_sh), 40sh_l=values(40sh_l), medic_h=values(medic_h), medic_l=values(medic_l), def_k=values(def_k), def_r=values(def_r), def_l=values(def_l), rpg_k=values(rpg_k), rpg_sf=values(rpg_sf), rpg_sh=values(rpg_sh), rpg_l=values(rpg_l), repair_k=values(repair_k), repair_t=values(repair_t), repair_l=values(repair_l), atm_k=values(atm_k), atm_sf=values(atm_sf), atm_sh=values(atm_sh), atm_l=values(atm_l), carl_k=values(carl_k), carl_sf=values(carl_sf), carl_sh=values(carl_sh), carl_l=values(carl_l), m136_k=values(m136_k), m136_sf=values(m136_sf), m136_sh=values(m136_sh), m136_l=values(m136_l), c4_k=values(c4_k), c4_t=values(c4_t), c4_l=values(c4_l), motion_sf=values(motion_sf), motion_t=values(motion_t), motion_l=values(motion_l), mort_k=values(mort_k), mort_sf=values(mort_sf), mort_sh=values(mort_sh), mort_l=values(mort_l), kni_k=values(kni_k), kni_t=values(kni_t), kni_l=values(kni_l), nade_k=values(nade_k), nade_t=values(nade_t), nade_l=values(nade_l), trac_sf=values(trac_sf), trac_sh=values(trac_sh), trac_l=values(trac_l), bay_k=values(bay_k), bay_l=values(bay_l)";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

$sql = "INSERT INTO vehiclestats VALUES ($persona, $currenttime, ".$vehiclestats[0]->getStat(0).", ".$vehiclestats[0]->getStat(1).", ".$vehiclestats[0]->getStat(2).", ".$vehiclestats[0]->getStat(3).", ".$vehiclestats[1]->getStat(0).", ".$vehiclestats[1]->getStat(1).", ".$vehiclestats[1]->getStat(2).", ".$vehiclestats[1]->getStat(3).", ".$vehiclestats[2]->getStat(0).", ".$vehiclestats[2]->getStat(1).", ".$vehiclestats[2]->getStat(2).", ".$vehiclestats[2]->getStat(3).", ".$vehiclestats[3]->getStat(0).", ".$vehiclestats[3]->getStat(1).", ".$vehiclestats[3]->getStat(2).", ".$vehiclestats[3]->getStat(3).", ".$vehiclestats[4]->getStat(0).", ".$vehiclestats[4]->getStat(1).", ".$vehiclestats[4]->getStat(2).", ".$vehiclestats[4]->getStat(3).", ".$vehiclestats[5]->getStat(0).", ".$vehiclestats[5]->getStat(1).", ".$vehiclestats[5]->getStat(2).", ".$vehiclestats[5]->getStat(3).", ".$vehiclestats[6]->getStat(0).", ".$vehiclestats[6]->getStat(1).", ".$vehiclestats[6]->getStat(2).", ".$vehiclestats[6]->getStat(3).", ".$vehiclestats[7]->getStat(0).", ".$vehiclestats[7]->getStat(1).", ".$vehiclestats[7]->getStat(2).", ".$vehiclestats[7]->getStat(3).", ".$vehiclestats[8]->getStat(0).", ".$vehiclestats[8]->getStat(1).", ".$vehiclestats[8]->getStat(2).", ".$vehiclestats[8]->getStat(3).", ".$vehiclestats[9]->getStat(0).", ".$vehiclestats[9]->getStat(1).", ".$vehiclestats[9]->getStat(2).", ".$vehiclestats[9]->getStat(3).", ".$vehiclestats[10]->getStat(0).", ".$vehiclestats[10]->getStat(1).", ".$vehiclestats[10]->getStat(2).", ".$vehiclestats[10]->getStat(3).", ".$vehiclestats[11]->getStat(0).", ".$vehiclestats[11]->getStat(1).", ".$vehiclestats[11]->getStat(2).", ".$vehiclestats[11]->getStat(3).", ".$vehiclestats[12]->getStat(0).", ".$vehiclestats[12]->getStat(1).", ".$vehiclestats[12]->getStat(2).", ".$vehiclestats[12]->getStat(3).", ".$vehiclestats[13]->getStat(0).", ".$vehiclestats[13]->getStat(1).", ".$vehiclestats[13]->getStat(2).", ".$vehiclestats[13]->getStat(3).", ".$vehiclestats[14]->getStat(0).", ".$vehiclestats[14]->getStat(1).", ".$vehiclestats[14]->getStat(2).", ".$vehiclestats[14]->getStat(3).", ".$vehiclestats[15]->getStat(0).", ".$vehiclestats[15]->getStat(1).", ".$vehiclestats[15]->getStat(2).", ".$vehiclestats[15]->getStat(3).", ".$vehiclestats[16]->getStat(0).", ".$vehiclestats[16]->getStat(1).", ".$vehiclestats[17]->getStat(0).", ".$vehiclestats[17]->getStat(1).", ".$vehiclestats[18]->getStat(0).", ".$vehiclestats[18]->getStat(1).", ".$vehiclestats[19]->getStat(0).", ".$vehiclestats[19]->getStat(1).", ".$vehiclestats[20]->getStat(0).", ".$vehiclestats[20]->getStat(1).
") ON DUPLICATE KEY UPDATE time=values(time), hmv_k=values(hmv_k), hmv_r=values(hmv_r), hmv_d=values(hmv_d), hmv_t=values(hmv_t), vod_k=values(vod_k), vod_r=values(vod_r), vod_d=values(vod_d), vod_t=values(vod_t), cob_r=values(cob_r), cob_d=values(cob_d), cob_t=values(cob_t), quad_k=values(quad_k), quad_r=values(quad_r), quad_d=values(quad_d), quad_t=values(quad_t), m1a2_k=values(m1a2_k), m1a2_r=values(m1a2_r), m1a2_d=values(m1a2_d), m1a2_t=values(m1a2_t), t90_k=values(t90_k), t90_r=values(t90_r), t90_d=values(t90_d), t90_t=values(t90_t), m3a3_k=values(m3a3_k), m3a3_r=values(m3a3_r), m3a3_d=values(m3a3_d), m3a3_t=values(m3a3_t), bmd_k=values(bmd_k), bmd_r=values(bmd_r), bmd_d=values(bmd_d), bmd_t=values(bmd_t), bmda_k=values(bmda_k), bmda_r=values(bmda_r), bmda_d=values(bmda_d), bmda_t=values(bmda_t), water_k=values(water_k), water_r=values(water_r), water_d=values(water_d), water_t=values(water_t), patrol_k=values(patrol_k), patrol_r=values(patrol_r), patrol_d=values(patrol_d), patrol_t=values(patrol_t), uh60_k=values(uh60_k), uh60_r=values(uh60_r), uh60_d=values(uh60_d), uh60_t=values(uh60_t), ah64_k=values(ah64_k), ah64_r=values(ah64_r), ah64_d=values(ah64_d), ah64_t=values(ah64_t), mi28_k=values(mi28_k), mi28_r=values(mi28_r), mi28_d=values(mi28_d), mi28_t=values(mi28_t), mi24_k=values(mi24_k), mi24_r=values(mi24_r), mi24_d=values(mi24_d), mi24_t=values(mi24_t), uav_k=values(uav_k), uav_r=values(uav_r), uav_d=values(uav_d), uav_t=values(uav_t), hmg1_k=values(hmg1_k), hmg1_t=values(hmg1_t), hmg2_k=values(hmg2_k), hmg2_t=values(hmg2_t), sat1_k=values(sat1_k), sat1_t=values(sat1_t), sat2_k=values(sat2_k), sat2_t=values(sat2_t), aag_k=values(aag_k), aag_t=values(aag_t)";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

print "Player $persona added successfully\n";
}

1;
