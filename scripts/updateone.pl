#!/usr/bin/perl -w

##########################################################################
# This script updates one player's stats.  If the -n option
# is used, it will add the player to the database first, then update
###########################################################################

use strict;
use WWW::Mechanize;
use Playerstats;
print "starting\n";
my $usage = "Usage: ./updateone.pl -n <username> <platform>\n       ./updateone.pl -u <persona> <platform>\n";
my $numargs = $#ARGV + 1;		
my ($persona, $username, $platform, $newuser);
if ($numargs > 2) { 
	if ($ARGV[0] eq "-n") {
		$username = $ARGV[1];
		$newuser = 1;
	}
	elsif ($ARGV[0] eq "-u") {
		$persona = $ARGV[1];
		$newuser = 0;
	}
	else{print "Invalid arguments\n"; exit(1);}
	$platform = $ARGV[2];
}
else {print "Not enough arguments\n"; exit(1);}
print "ending\n";
my $agent = WWW::Mechanize->new();
Playerstats::passAgeGate($agent);
if ($newuser) {$persona = Playerstats::newPlayer($agent, $username, $platform);}
if ($persona < 0) {die("Player not found");}
Playerstats::updatePlayerStats($agent, $persona, $platform, 0);
print "finished\n";
