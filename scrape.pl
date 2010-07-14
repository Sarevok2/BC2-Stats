#!/usr/bin/perl -w
use strict;
use WWW::Mechanize;
use HTML::TokeParser;
use Itemstat;
use DBI;

######################### subroutines ##############################

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

######################### Browse to stats page ##############################

my $numargs = $#ARGV + 1;
my $username;
my $platform;
if ($numargs > 1) {
	$username = $ARGV[0];
	$platform = $ARGV[1];
}
else {die("Usage: perl scrape.pl <username> <platform>");}

my $agent = WWW::Mechanize->new();

$agent->get("http://badcompany2.ea.com/leaderboards");
$agent->form_number(1);
$agent->field("age", "20");
$agent->click();

#$agent->get("http://www.badcompany2.ea.com//globalstats/ajax?platform=pc&sort=score&start=1&search=sureshot324");

print $username."\n";
$agent->get("http://www.badcompany2.ea.com/leaderboards/ajax?platform=" . $platform . "&sort=score&start=1&search=" . $username);
my $text = $agent->content();

die ("Failed to locate player") unless ($text =~ /persona=(\d{9})/);

my $persona = $1;
#my $persona = 234354084;

$agent->get("http://www.badcompany2.ea.com/stats?persona=" . $persona . "&platform=" . $platform);

######################### Parse stats ##############################

my $stream = HTML::TokeParser->new(\$agent->{content});
#my $stream = HTML::TokeParser->new("playerstats.html");


find_class($stream, "div", "stat-fields");
#find_class($stream, "span", "value");
#my $position = $stream->get_text();
#print("Position: " . $position . "\n");
my $position = 10001; #position is glitched on the site for now
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
print("Score per min: " . $scoremin . "\n");

find_class($stream, "span", "value");
my $kd = $stream->get_text();
print("Kill/Death ratio: " . $kd . "\n");

find_class($stream, "span", "value");
my $totalscore = $stream->get_text();
$totalscore =~ tr/ //d;
print("Total Score: " . $totalscore . "\n");

find_class($stream, "div", "rank-info");
my $tag = $stream->get_tag("img");
my $imgsrc = $tag->[1]{src};
my $rank = 1;
if ($imgsrc){
	if ($imgsrc =~ /.*R0(\d{2}).{4}$/) {$rank = $1;}
}
print("Rank: " . $rank . "\n");

my $nextrankprog = 0;
my $nextrankgoal = 0;
if ($rank ne 50) {
  find_class($stream, "div", "rank-score");
  my @temp = split(/\//, $stream->get_text());
  $nextrankprog = $temp[0];
  $nextrankgoal = $temp[1];
  $nextrankprog =~ tr/ //d;
  $nextrankgoal =~ tr/ //d;
  print("To Next Rank: " . $nextrankprog . "/" . $nextrankgoal . "\n");
}

find_class($stream, "div", "stats-block stats-block-right");

find_class($stream, "span", "value");
my $assaultscore = $stream->get_text();
$assaultscore =~ tr/\+ //d;
print("Assault Score: " . $assaultscore . "\n");

find_class($stream, "span", "value");
my $medicscore = $stream->get_text();
$medicscore =~ tr/\+ //d;
print("Medic Score: " . $medicscore . "\n");

find_class($stream, "span", "value");
my $reconscore = $stream->get_text();
$reconscore =~ tr/\+ //d;
print("Recon Score: " . $reconscore . "\n");

find_class($stream, "span", "value");
my $engineerscore = $stream->get_text();
$engineerscore =~ tr/\+ //d;
print("engineer Score: " . $engineerscore . "\n");

find_class($stream, "span", "value");
my $vehiclescore = $stream->get_text();
$vehiclescore =~ tr/\+ //d;
print("vehicle Score: " . $vehiclescore . "\n");

find_class($stream, "span", "value");
my $combatscore = $stream->get_text();
$combatscore =~ tr/\= //d;
print("combat Score: " . $combatscore . "\n");

find_class($stream, "span", "value");
my $awardscore = $stream->get_text();
$awardscore =~ tr/\+ //d;
print("award Score: " . $awardscore . "\n");

find_class($stream, "span", "value");

find_class($stream, "span", "value");
my $kills = $stream->get_text();
$kills =~ tr/ //d;
print("kills: " . $kills . "\n");

find_class($stream, "span", "value");
my $deaths = $stream->get_text();
$deaths =~ tr/ //d;
print("Deaths: " . $deaths . "\n");

######################### favorites ##############################

find_class($stream, "div", "stat-field-big");

$stream->get_tag("span");
my $favweap = $stream->get_text();
print("Favorite weapon: " . $favweap . "\n");

find_class($stream, "span", "value");
my $killswithfav = $stream->get_text();
print("Kills with favorite: " . $killswithfav . "\n");

find_class($stream, "span", "value");
my $shotswithfav = $stream->get_text();
print("Shots fired with favorite: " . $shotswithfav . "\n");

find_class($stream, "span", "value");
my $accwithfav = $stream->get_text();
print("Accuracy with favorite: " . $accwithfav . "\n");

find_class($stream, "div", "stat-field-big");

$stream->get_tag("span");
my $favveh = $stream->get_text();
print("Favorite vehicle: " . $favveh . "\n");

find_class($stream, "span", "value");
my $killswithveh = $stream->get_text();
print("Kills with favorite vehicle: " . $killswithveh . "\n");

find_class($stream, "span", "value");
my $roadkills= $stream->get_text();
print("Roadkills: " . $roadkills . "\n");

find_class($stream, "span", "value");
my $distance = $stream->get_text();
print("distance driven: " . $distance . "\n");

########################### weapon stats #############################
print "loading guns\n";

$agent->get("http://www.badcompany2.ea.com/weaponsgadgets/ajax?platform=" . $platform . "&persona=" . $persona . "&cat=weapons");
$stream = HTML::TokeParser->new(\$agent->{content});

my @gunstats = getItemStats(46, $stream);


########################## gadgets ##################################

print "loading gadgets\n";

$agent->get("http://www.badcompany2.ea.com/weaponsgadgets/ajax?platform=" . $platform . "&persona=" . $persona . "&cat=gadgets");
$stream = HTML::TokeParser->new(\$agent->{content});

my @gadgetstats = getItemStats(18, $stream);

########################## vehicles ##################################

print "loading vehicles\n";

$agent->get("http://www.badcompany2.ea.com/weaponsgadgets/ajax?platform=" . $platform . "&persona=" . $persona . "&cat=vehicles");
$stream = HTML::TokeParser->new(\$agent->{content});

my @vehiclestats = getItemStats(21, $stream);

######################### Mysql ##############################

print "storing in mysql\n";

my $host = "localhost";
my $db = "sarevok";
my $user = "na";
my $pw = "na";

my $usrtable = "users";
my $statstable = "stats";

my $dbh = DBI->connect( "dbi:mysql:$db", $user, $pw, { 'PrintError' => 1, 'RaiseError' => 1 } );

my $currenttime = time;

my $sql = "INSERT IGNORE INTO bc2users values ($persona, '$username')";
my $sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

$sql = "INSERT INTO mainstats VALUES ($persona, $currenttime, $position, $timeplayed, $kills, $deaths, $rank, $nextrankprog, $nextrankgoal, $assaultscore, $medicscore, $reconscore, $engineerscore, $vehiclescore, $combatscore, $awardscore)";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

$sql = "INSERT INTO gunstats VALUES ($persona, $currenttime, ".$gunstats[0]->getStat(0).", ".$gunstats[0]->getStat(1).", ".$gunstats[0]->getStat(2).", ".$gunstats[0]->getStat(3).", ".$gunstats[0]->isLocked().", ".$gunstats[1]->getStat(0).", ".$gunstats[1]->getStat(1).", ".$gunstats[1]->getStat(2).", ".$gunstats[1]->getStat(3).", ".$gunstats[1]->isLocked().", ".$gunstats[2]->getStat(0).", ".$gunstats[2]->getStat(1).", ".$gunstats[2]->getStat(2).", ".$gunstats[2]->getStat(3).", ".$gunstats[2]->isLocked().", ".$gunstats[3]->getStat(0).", ".$gunstats[3]->getStat(1).", ".$gunstats[3]->getStat(2).", ".$gunstats[3]->getStat(3).", ".$gunstats[3]->isLocked().", ".$gunstats[4]->getStat(0).", ".$gunstats[4]->getStat(1).", ".$gunstats[4]->getStat(2).", ".$gunstats[4]->getStat(3).", ".$gunstats[4]->isLocked().", ".$gunstats[5]->getStat(0).", ".$gunstats[5]->getStat(1).", ".$gunstats[5]->getStat(2).", ".$gunstats[5]->getStat(3).", ".$gunstats[5]->isLocked().", ".$gunstats[6]->getStat(0).", ".$gunstats[6]->getStat(1).", ".$gunstats[6]->getStat(2).", ".$gunstats[6]->getStat(3).", ".$gunstats[6]->isLocked().", ".$gunstats[7]->getStat(0).", ".$gunstats[7]->getStat(1).", ".$gunstats[7]->getStat(2).", ".$gunstats[7]->getStat(3).", ".$gunstats[7]->isLocked().", ".$gunstats[8]->getStat(0).", ".$gunstats[8]->getStat(1).", ".$gunstats[8]->getStat(2).", ".$gunstats[8]->getStat(3).", ".$gunstats[8]->isLocked().", ".$gunstats[9]->getStat(0).", ".$gunstats[9]->getStat(1).", ".$gunstats[9]->getStat(2).", ".$gunstats[9]->getStat(3).", ".$gunstats[9]->isLocked().", ".$gunstats[10]->getStat(0).", ".$gunstats[10]->getStat(1).", ".$gunstats[10]->getStat(2).", ".$gunstats[10]->getStat(3).", ".$gunstats[10]->isLocked().", ".$gunstats[11]->getStat(0).", ".$gunstats[11]->getStat(1).", ".$gunstats[11]->getStat(2).", ".$gunstats[11]->getStat(3).", ".$gunstats[11]->isLocked().", ".$gunstats[12]->getStat(0).", ".$gunstats[12]->getStat(1).", ".$gunstats[12]->getStat(2).", ".$gunstats[12]->getStat(3).", ".$gunstats[12]->isLocked().", ".$gunstats[13]->getStat(0).", ".$gunstats[13]->getStat(1).", ".$gunstats[13]->getStat(2).", ".$gunstats[13]->getStat(3).", ".$gunstats[13]->isLocked().", ".$gunstats[14]->getStat(0).", ".$gunstats[14]->getStat(1).", ".$gunstats[14]->getStat(2).", ".$gunstats[14]->getStat(3).", ".$gunstats[14]->isLocked().", ".$gunstats[15]->getStat(0).", ".$gunstats[15]->getStat(1).", ".$gunstats[15]->getStat(2).", ".$gunstats[15]->getStat(3).", ".$gunstats[15]->isLocked().", ".$gunstats[16]->getStat(0).", ".$gunstats[16]->getStat(1).", ".$gunstats[16]->getStat(2).", ".$gunstats[16]->getStat(3).", ".$gunstats[16]->isLocked().", ".$gunstats[17]->getStat(0).", ".$gunstats[17]->getStat(1).", ".$gunstats[17]->getStat(2).", ".$gunstats[17]->getStat(3).", ".$gunstats[17]->isLocked().", ".$gunstats[18]->getStat(0).", ".$gunstats[18]->getStat(1).", ".$gunstats[18]->getStat(2).", ".$gunstats[18]->getStat(3).", ".$gunstats[18]->isLocked().", ".$gunstats[19]->getStat(0).", ".$gunstats[19]->getStat(1).", ".$gunstats[19]->getStat(2).", ".$gunstats[19]->getStat(3).", ".$gunstats[19]->isLocked().", ".$gunstats[20]->getStat(0).", ".$gunstats[20]->getStat(1).", ".$gunstats[20]->getStat(2).", ".$gunstats[20]->getStat(3).", ".$gunstats[20]->isLocked().", ".$gunstats[21]->getStat(0).", ".$gunstats[21]->getStat(1).", ".$gunstats[21]->getStat(2).", ".$gunstats[21]->getStat(3).", ".$gunstats[21]->isLocked().", ".$gunstats[22]->getStat(0).", ".$gunstats[22]->getStat(1).", ".$gunstats[22]->getStat(2).", ".$gunstats[22]->getStat(3).", ".$gunstats[22]->isLocked().", ".$gunstats[23]->getStat(0).", ".$gunstats[23]->getStat(1).", ".$gunstats[23]->getStat(2).", ".$gunstats[23]->getStat(3).", ".$gunstats[23]->isLocked().", ".$gunstats[24]->getStat(0).", ".$gunstats[24]->getStat(1).", ".$gunstats[24]->getStat(2).", ".$gunstats[24]->getStat(3).", ".$gunstats[24]->isLocked().", ".$gunstats[25]->getStat(0).", ".$gunstats[25]->getStat(1).", ".$gunstats[25]->getStat(2).", ".$gunstats[25]->getStat(3).", ".$gunstats[25]->isLocked().", ".$gunstats[26]->getStat(0).", ".$gunstats[26]->getStat(1).", ".$gunstats[26]->getStat(2).", ".$gunstats[26]->getStat(3).", ".$gunstats[26]->isLocked().", ".$gunstats[27]->getStat(0).", ".$gunstats[27]->getStat(1).", ".$gunstats[27]->getStat(2).", ".$gunstats[27]->getStat(3).", ".$gunstats[27]->isLocked().", ".$gunstats[28]->getStat(0).", ".$gunstats[28]->getStat(1).", ".$gunstats[28]->getStat(2).", ".$gunstats[28]->getStat(3).", ".$gunstats[28]->isLocked().", ".$gunstats[29]->getStat(0).", ".$gunstats[29]->getStat(1).", ".$gunstats[29]->getStat(2).", ".$gunstats[29]->getStat(3).", ".$gunstats[29]->isLocked().", ".$gunstats[30]->getStat(0).", ".$gunstats[30]->getStat(1).", ".$gunstats[30]->getStat(2).", ".$gunstats[30]->getStat(3).", ".$gunstats[30]->isLocked().", ".$gunstats[31]->getStat(0).", ".$gunstats[31]->getStat(1).", ".$gunstats[31]->getStat(2).", ".$gunstats[31]->getStat(3).", ".$gunstats[31]->isLocked().", ".$gunstats[32]->getStat(0).", ".$gunstats[32]->getStat(1).", ".$gunstats[32]->getStat(2).", ".$gunstats[32]->getStat(3).", ".$gunstats[32]->isLocked().", ".$gunstats[33]->getStat(0).", ".$gunstats[33]->getStat(1).", ".$gunstats[33]->getStat(2).", ".$gunstats[33]->getStat(3).", ".$gunstats[33]->isLocked().", ".$gunstats[34]->getStat(0).", ".$gunstats[34]->getStat(1).", ".$gunstats[34]->getStat(2).", ".$gunstats[34]->getStat(3).", ".$gunstats[34]->isLocked().", ".$gunstats[35]->getStat(0).", ".$gunstats[35]->getStat(1).", ".$gunstats[35]->getStat(2).", ".$gunstats[35]->getStat(3).", ".$gunstats[35]->isLocked().", ".$gunstats[36]->getStat(0).", ".$gunstats[36]->getStat(1).", ".$gunstats[36]->getStat(2).", ".$gunstats[36]->getStat(3).", ".$gunstats[36]->isLocked().", ".$gunstats[37]->getStat(0).", ".$gunstats[37]->getStat(1).", ".$gunstats[37]->getStat(2).", ".$gunstats[37]->getStat(3).", ".$gunstats[37]->isLocked().", ".$gunstats[38]->getStat(0).", ".$gunstats[38]->getStat(1).", ".$gunstats[38]->getStat(2).", ".$gunstats[38]->getStat(3).", ".$gunstats[38]->isLocked().", ".$gunstats[39]->getStat(0).", ".$gunstats[39]->getStat(1).", ".$gunstats[39]->getStat(2).", ".$gunstats[39]->getStat(3).", ".$gunstats[39]->isLocked().", ".$gunstats[40]->getStat(0).", ".$gunstats[40]->getStat(1).", ".$gunstats[40]->getStat(2).", ".$gunstats[40]->getStat(3).", ".$gunstats[40]->isLocked().", ".$gunstats[41]->getStat(0).", ".$gunstats[41]->getStat(1).", ".$gunstats[41]->getStat(2).", ".$gunstats[41]->getStat(3).", ".$gunstats[41]->isLocked().", ".$gunstats[42]->getStat(0).", ".$gunstats[42]->getStat(1).", ".$gunstats[42]->getStat(2).", ".$gunstats[42]->getStat(3).", ".$gunstats[42]->isLocked().", ".$gunstats[43]->getStat(0).", ".$gunstats[43]->getStat(1).", ".$gunstats[43]->getStat(2).", ".$gunstats[43]->getStat(3).", ".$gunstats[43]->isLocked().", ".$gunstats[44]->getStat(0).", ".$gunstats[44]->getStat(1).", ".$gunstats[44]->getStat(2).", ".$gunstats[44]->getStat(3).", ".$gunstats[44]->isLocked().", ".$gunstats[45]->getStat(0).", ".$gunstats[45]->getStat(1).", ".$gunstats[45]->getStat(2).", ".$gunstats[45]->getStat(3).", ".$gunstats[45]->isLocked().")";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

$sql = "INSERT INTO gadgetstats VALUES ($persona, $currenttime, ".$gadgetstats[0]->getStat(0).", ".$gadgetstats[0]->getStat(1).", ".$gadgetstats[0]->getStat(2).", ".$gadgetstats[0]->isLocked().", ".$gadgetstats[1]->getStat(0).", ".$gadgetstats[1]->isLocked().", ".$gadgetstats[2]->getStat(0).", ".$gadgetstats[2]->isLocked().", ".$gadgetstats[3]->getStat(0).", ".$gadgetstats[3]->getStat(1).", ".$gadgetstats[3]->getStat(2).", ".$gadgetstats[3]->isLocked().", ".$gadgetstats[4]->getStat(0).", ".$gadgetstats[4]->isLocked().", ".$gadgetstats[5]->getStat(0).", ".$gadgetstats[5]->getStat(1).", ".$gadgetstats[5]->isLocked().", ".$gadgetstats[6]->getStat(0).", ".$gadgetstats[6]->getStat(1).", ".$gadgetstats[6]->getStat(2).", ".$gadgetstats[6]->isLocked().", ".$gadgetstats[7]->getStat(0).", ".$gadgetstats[7]->getStat(1).", ".$gadgetstats[7]->isLocked().", ".$gadgetstats[8]->getStat(0).", ".$gadgetstats[8]->getStat(1).", ".$gadgetstats[8]->getStat(2).", ".$gadgetstats[8]->isLocked().", ".$gadgetstats[9]->getStat(0).", ".$gadgetstats[9]->getStat(1).", ".$gadgetstats[9]->getStat(2).", ".$gadgetstats[9]->isLocked().", ".$gadgetstats[10]->getStat(0).", ".$gadgetstats[10]->getStat(1).", ".$gadgetstats[10]->getStat(2).", ".$gadgetstats[10]->isLocked().", ".$gadgetstats[11]->getStat(0).", ".$gadgetstats[11]->getStat(1).", ".$gadgetstats[11]->isLocked().", ".$gadgetstats[12]->getStat(0).", ".$gadgetstats[12]->getStat(1).", ".$gadgetstats[12]->isLocked().", ".$gadgetstats[13]->getStat(0).", ".$gadgetstats[13]->getStat(1).", ".$gadgetstats[13]->getStat(2).", ".$gadgetstats[13]->isLocked().", ".$gadgetstats[14]->getStat(0).", ".$gadgetstats[14]->getStat(1).", ".$gadgetstats[14]->isLocked().", ".$gadgetstats[15]->getStat(0).", ".$gadgetstats[15]->getStat(1).", ".$gadgetstats[15]->isLocked().", ".$gadgetstats[16]->getStat(0).", ".$gadgetstats[16]->getStat(1).", ".$gadgetstats[16]->isLocked().", ".$gadgetstats[17]->getStat(0).", ".$gadgetstats[17]->isLocked().")";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

$sql = "INSERT INTO vehiclestats VALUES ($persona, $currenttime, ".$vehiclestats[0]->getStat(0).", ".$vehiclestats[0]->getStat(1).", ".$vehiclestats[0]->getStat(2).", ".$vehiclestats[0]->getStat(3).", ".$vehiclestats[1]->getStat(0).", ".$vehiclestats[1]->getStat(1).", ".$vehiclestats[1]->getStat(2).", ".$vehiclestats[1]->getStat(3).", ".$vehiclestats[2]->getStat(0).", ".$vehiclestats[2]->getStat(1).", ".$vehiclestats[2]->getStat(2).", ".$vehiclestats[2]->getStat(3).", ".$vehiclestats[3]->getStat(0).", ".$vehiclestats[3]->getStat(1).", ".$vehiclestats[3]->getStat(2).", ".$vehiclestats[3]->getStat(3).", ".$vehiclestats[4]->getStat(0).", ".$vehiclestats[4]->getStat(1).", ".$vehiclestats[4]->getStat(2).", ".$vehiclestats[4]->getStat(3).", ".$vehiclestats[5]->getStat(0).", ".$vehiclestats[5]->getStat(1).", ".$vehiclestats[5]->getStat(2).", ".$vehiclestats[5]->getStat(3).", ".$vehiclestats[6]->getStat(0).", ".$vehiclestats[6]->getStat(1).", ".$vehiclestats[6]->getStat(2).", ".$vehiclestats[6]->getStat(3).", ".$vehiclestats[7]->getStat(0).", ".$vehiclestats[7]->getStat(1).", ".$vehiclestats[7]->getStat(2).", ".$vehiclestats[7]->getStat(3).", ".$vehiclestats[8]->getStat(0).", ".$vehiclestats[8]->getStat(1).", ".$vehiclestats[8]->getStat(2).", ".$vehiclestats[8]->getStat(3).", ".$vehiclestats[9]->getStat(0).", ".$vehiclestats[9]->getStat(1).", ".$vehiclestats[9]->getStat(2).", ".$vehiclestats[9]->getStat(3).", ".$vehiclestats[10]->getStat(0).", ".$vehiclestats[10]->getStat(1).", ".$vehiclestats[10]->getStat(2).", ".$vehiclestats[10]->getStat(3).", ".$vehiclestats[11]->getStat(0).", ".$vehiclestats[11]->getStat(1).", ".$vehiclestats[11]->getStat(2).", ".$vehiclestats[11]->getStat(3).", ".$vehiclestats[12]->getStat(0).", ".$vehiclestats[12]->getStat(1).", ".$vehiclestats[12]->getStat(2).", ".$vehiclestats[12]->getStat(3).", ".$vehiclestats[13]->getStat(0).", ".$vehiclestats[13]->getStat(1).", ".$vehiclestats[13]->getStat(2).", ".$vehiclestats[13]->getStat(3).", ".$vehiclestats[14]->getStat(0).", ".$vehiclestats[14]->getStat(1).", ".$vehiclestats[14]->getStat(2).", ".$vehiclestats[14]->getStat(3).", ".$vehiclestats[15]->getStat(0).", ".$vehiclestats[15]->getStat(1).", ".$vehiclestats[15]->getStat(2).", ".$vehiclestats[15]->getStat(3).", ".$vehiclestats[16]->getStat(0).", ".$vehiclestats[16]->getStat(1).", ".$vehiclestats[17]->getStat(0).", ".$vehiclestats[17]->getStat(1).", ".$vehiclestats[18]->getStat(0).", ".$vehiclestats[18]->getStat(1).", ".$vehiclestats[19]->getStat(0).", ".$vehiclestats[19]->getStat(1).", ".$vehiclestats[20]->getStat(0).", ".$vehiclestats[20]->getStat(1).")";

$sql_handle=$dbh->prepare($sql);
$sql_handle->execute();
