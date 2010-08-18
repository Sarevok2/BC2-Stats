package GetLeaderBoards;

use strict;
use DBI;
use WWW::Mechanize;

my $host = "localhost";
my $db = "sarevok";
my $user = "sarevok";
my $pw = "JohnMayL1v3s";

sub getLeaders {
	my ($agent, $platform) = @_;
	
	my $platformnum;
	if ($platform eq "pc") {$platformnum = 1;}
	elsif ($platform eq "360") {$platformnum = 2;}
	elsif ($platform eq "ps3") {$platformnum = 3;}

	$agent->get("http://www.badcompany2.ea.com/leaderboards/ajax?platform=" . $platform . "&sort=score&start=1");
	
	my $text = $agent->content();

	my $dbh = DBI->connect( "dbi:mysql:$db", $user, $pw, { 'PrintError' => 1, 'RaiseError' => 1 } );

	while ($text =~ /persona=(\d{9})\\x26platform=.{2,3}\\\"\\x3e\\x3cdiv\\x3e(.{0,40})\\x3c\/div/g) {
		my $sql = "INSERT IGNORE INTO bc2users VALUES ($1, '$2', $platformnum, " . time . ")";
		my $sql_handle=$dbh->prepare($sql);
		$sql_handle->execute();
	}
}

1;
	


