package Itemstat;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $itemstats = {
		statlist => [],
		locked => 0
	};
	bless $itemstats, $class;
	return $itemstats;	
}

sub getStat {
	my ($itemstats, $index) = @_;
	my $num = $itemstats->{statlist}[$index];
	if ($num) {return $num;}
	else {return 0};
}

sub isLocked {
   my ($itemstats) = @_;
   return $itemstats->{locked};
}

sub addStat {
  my ( $itemstats, $stat ) = @_;
  push(@{$itemstats->{statlist}}, $stat) if defined($stat);
}

sub lock {
  my ($itemstats) = @_;
  $itemstats->{locked} = 1;
}

sub printStats {
	my ($itemstats) = @_;
	print "Item stats:\n";
	my @list  = @{$itemstats->{statlist}};
	foreach (@list) {
		print $_ . " ";
	}
	print "Locked: " . $itemstats->{locked} . "\n\n";
}

1;




