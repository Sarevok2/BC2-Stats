#!/usr/bin/perl -w
use strict;
use WWW::Mechanize;
use DBI;
use Playerstats;
use GetLeaderBoards;

my $host = "localhost";
my $db = "sarevok";
my $user = "sarevok";
my $pw = "JohnMayL1v3s";

##### Initialize the WWW::Mechanize object and pass the age age gate.

my $agent = WWW::Mechanize->new();
Playerstats::passAgeGate($agent);

GetLeaderBoards::getLeaders($agent, "360");
GetLeaderBoards::getLeaders($agent, "pc");
GetLeaderBoards::getLeaders($agent, "ps3");


my $dbh = DBI->connect("dbi:mysql:$db", $user, $pw, { 'PrintError' => 1, 'RaiseError' => 1 } );

my $sql = "SELECT persona,platform FROM bc2users";
my $sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

while (my ($persona, $platformnum) = $sql_handle->fetchrow_array()) {
	my $platform;
	if ($platformnum == 1) {$platform = "pc";}
	elsif ($platformnum == 2) {$platform = "360";}
	elsif ($platformnum == 3) {$platform = "ps3";}

	Playerstats::updatePlayerStats($agent, $persona, $platform, 1);
}

#should also clear out old stuff out of weeklystats
