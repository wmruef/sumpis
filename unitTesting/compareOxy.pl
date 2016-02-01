#!/usr/bin/perl
use strict;


opendir SEA,"processed_seabird" or 
  die "Could not open Seabird processed directory!\n";
my %orcaCASTs = ();
my %seabirdFiles = ();
while ( my $entry = readdir(SEA) )
{
  #ORCA1_CAST28929_align_derive.cnv
  if ( $entry =~ /(\S+)_align_derive.cnv/ )
  {
    $orcaCASTs{$1}++;
    $seabirdFiles{$entry}++;
  }
}
closedir( SEA );

my $compareAll = 0;

opendir CMP,"processed_compare/201601" or 
  die "Could not open processed_compare/201601 directory!\n";
my %compareFiles = ();
while ( my $entry = readdir(CMP) )
{
  #ORCA1_CAST28921.HTA
  if ( $entry =~ /(\S+)\.HTA/ )
  {
    $orcaCASTs{$1}++;
    $compareFiles{$entry}++;
  }
}
closedir( CMP );


compareFiles( "processed_compare/201601/ORCA1_CAST28921.HTA", "processed_seabird_noalign/ORCA1_CAST28921" . "deriveONLY.cnv" );


foreach my $cast ( keys( %orcaCASTs ) )
{
  if ( $orcaCASTs{$cast} > 1 )
  {
    print "Comparing $cast\n";
    compareFiles( "processed_compare/201601/$cast.HTA", "processed_seabird/$cast" . "_align_derive.cnv" );
    last unless( $compareAll );
  }
}


sub compareFiles
{
  my $sumpis_file = shift;
  my $seabird_file = shift;

  open IN,"<$sumpis_file" or 
    die "Could not open $sumpis_file for reading!\n";
  my @sumpisOxyVals = ();
  while ( <IN> )
  {
    #*END*
    #	1	19.547	28.351	445867.000	5498.125	11.6266	3.431535	0.8
    #	482	0.0002	0.1791	0.3977	0.9966	0.6747	19.383	29.8038	22.6237	1.31645	1.88134	57.
    #	492	6.30169	9.00574	0.0000e+00
    if ( /^\s*(\d+.*)/ )
    {
      my @fields = split(/\s+/, $1 );
      push @sumpisOxyVals, $fields[16];
    }
  }
  close IN;

  open IN,"<$seabird_file" or 
    die "Could not open $seabird_file for reading!\n";
  my @seabirdOxyVals = ();
  while ( <IN> )
  {
    if ( /^\s*(\d+.*)/ )
    {
      my @fields = split(/\s+/, $1 );
      push @seabirdOxyVals, $fields[16];
    }
  }
  close IN;

  warn "Array size mismatch!\n" if ( $#seabirdOxyVals != $#sumpisOxyVals );
  print "Seabird\tSumpis\tDiff\n";
  for ( my $i = 0; $i <= $#seabirdOxyVals; $i++ )
  {
    print "" . sprintf("%10f  %10f  %10f", $seabirdOxyVals[$i], $sumpisOxyVals[$i], abs( $seabirdOxyVals[$i] - $sumpisOxyVals[$i] ) ) . "\n";
  }
}
