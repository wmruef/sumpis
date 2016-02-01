#!/usr/bin/perl
use strict;

my $start = 0;
while ( <> )
{
  # DS
  if ( /^DS\s*$/ )
  {
    $start = 1;
  }
  # S>DC
  if ( /^S>DC\s*$/ )
  {
    $start = 0;
    print "*END*\n";
    next;
  }
  if ( $start )
  { 
    print "*$_";
  }else
  {
    print;
  }
}

