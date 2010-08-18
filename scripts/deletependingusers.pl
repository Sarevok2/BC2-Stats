#!/usr/bin/perl -w
use strict;
use DBI;

my $host = "localhost";
my $db = "sarevok";
my $user = "sarevok";
my $pw = "JohnMayL1v3s";

my $dbh = DBI->connect( "dbi:mysql:$db", $user, $pw, { 'PrintError' => 1, 'RaiseError' => 1 } );

my $deleteage = time-3600;#delete anything more than an hour old
my $sql = "DELETE FROM pendingusers WHERE lastupdate < ".$deleteage;
my $sql_handle=$dbh->prepare($sql);
$sql_handle->execute();

print "Pending users deleted\n";
