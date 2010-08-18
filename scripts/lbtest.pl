#!/usr/bin/perl -w
use strict;
use GetLeaderBoards;

my $agent = WWW::Mechanize->new();

GetLeaderBoards::getLeaders($agent, "pc");
