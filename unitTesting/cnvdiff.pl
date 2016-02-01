#!/usr/bin/perl
##---------------------------------------------------------------------------##
##  File:
##      @(#) cnvdiff.pl
##  Author:
##      Robert M. Hubley   rhubley@systemsbiology.org
##  Description:
##      Compare two Seabird cnv files and display the differences.
##
#******************************************************************************
#*  This software is provided ``AS IS'' and any express or implied            *
#*  warranties, including, but not limited to, the implied warranties of      *
#*  merchantability and fitness for a particular purpose, are disclaimed.     *
#*  In no event shall the authors or the Univ of Washington                   *
#*  liable for any direct, indirect, incidental, special, exemplary, or       *
#*  consequential damages (including, but not limited to, procurement of      *
#*  substitute goods or services; loss of use, data, or profits; or           *
#*  business interruption) however caused and on any theory of liability,     *
#*  whether in contract, strict liability, or tort (including negligence      *
#*  or otherwise) arising in any way out of the use of this software, even    *
#*  if advised of the possibility of such damage.                             *
#*                                                                            *
#******************************************************************************
#
# ChangeLog
#
#     $Log$
#
###############################################################################
#
# To Do:
#
=head1 NAME

cnvdiff.pl - Compare two Seabird .cnv files and display the differences.

=head1 SYNOPSIS

  cnvdiff.pl [-version] <file1> <file2>

=head1 DESCRIPTION

The options are:

=item <file1>

First file to compare.

=item <file2>

Second file to compare.

=item -version

Displays the version of the program

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright 2006 Robert Hubley

=head1 AUTHOR

Robert Hubley <rhubley@gmail.com>

=cut

#
# Module Dependence
#
use strict;
use Getopt::Long;
use Data::Dumper;


# Version
my $Version = "0.1";

#
# Option processing
#  e.g.
#   -t: Single letter binary option
#   -t=s: String parameters
#   -t=i: Number paramters
#
my @getopt_args = (
    '-version', # print out the version and exit
    '-v'
);

my %options = ();
Getopt::Long::config("noignorecase", "bundling_override");
unless (GetOptions(\%options, @getopt_args)) {
    usage();
}

sub usage {
  print "$0 - $Version\n";
  exec "pod2text $0";
  exit;
}

if ($options{'version'}) {
  print "$Version\n";
  exit;
}

my $verbose = 0;
$verbose = 1 if ( $options{'v'} );

# Validate paramters
if ( ! -f $ARGV[0] || ! -f $ARGV[1] ) {
  usage();
}

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

open IN1, "<$file1" or die "Cannot open $file1!\n";
# Move up to the data columns
while ( <IN1> ) 
{
  last if /\*END\*/;
}

open IN2, "<$file2" or die "Cannot open $file2!\n";
# Move up to the data columns
while ( <IN2> ) 
{
  last if /\*END\*/;
}

##
## Column tolerances
##
##  Stored in a hash as:
##    ( col# => tolerance, col# => tolerance )
##  ie. 
##       my %colTolerances = ( 3 => 0.001, 5 => 0.02 );
##
##  If not defined then use default tolerance instead
##
my $defTolerance = 10;
my %colTolerances = ( 0 => 0,             # Scan count
                      1 => 0.0011,        # prdM: Pressure, Strain Gauge [db]
                      2 => 0.002,         # prdE: Pressure, Strain Gauge [psi]
                      3 => 0.0011,        # f0: Frequency 0
                      4 => 0.0011,        # f1: Frequency 1
                      5 => 0.00011,       # tv290C: Temperature [ITS-90, deg C]
                      6 => 0.00011,       # c0S/m: Conductivity [S/m]
                      7 => 0,             # v0: Voltage 0
                      8 => 0,             # v1: Voltage 1
                      9 => 0,             # v2: Voltage 2
                      10 => 0,            # v3: Voltage 3
                      11 => 0,            # sbeox0V: Oxygen raw, SBE 43 [V]
                      12 => 0,            # wetStar: Fluorescence, WET Labs [mg/m^3]
                      13 => 0.0011,       # depSM: Depth [salt water, m], lat = 47.372
                      14 => 0.00011,      # sal00: Salinity, Practical [PSU]
                      15 => 0.00011,      # sigma-t00: Density [sigma-t, kg/m^3 ]
                      16 => 0.0001,       # sbeox0ML/L: Oxygen, SBE 43 [ml/l], WS = 0
                      17 => 0.0001,       # sbeox0Mg/L: Oxygen, SBE 43 [mg/l], WS = 0
                      18 => 0.002,        # sbeox0Mm/Kg: Oxygen, SBE 43 [umol/kg], WS = 0
                      19 => 0.00011,      # oxsatML/L: Oxygen Saturation, Weiss [ml/l]
                      20 => 0.00011,      # oxsatMg/L: Oxygen Saturation, Weiss [mg/l]
                      21 => 0);
     
my $coldiff;
my $row = 1;
my %minDiffs = ();
my %maxDiffs = ();
while ( 1 ) 
{
  last if ( eof( IN1 ) || eof( IN2 ) );
  my $line1 = <IN1>;
  my $line2 = <IN2>;
  my @cols1 = split( " ", $line1 );
  my @cols2 = split( " ", $line2 );
 
  if ( @cols1 != @cols2 ) 
  {
    print "Row $row does not contain the same number of columns!\n";
    next;
  }

  for ( my $i = 0; $i <= $#cols1; $i++ ) 
  {
    if ( ( defined $colTolerances{ $i } &&
           abs($cols1[$i] - $cols2[$i]) > $colTolerances{ $i } ) ||
         ( abs($cols1[$i] - $cols2[$i]) > $defTolerance ) ) 
    {
      if ( $verbose )
      {
        print "File1:\n";
        print "" . join( " ", @cols1 ) . "\n";
        print "File2:\n";
        print "" . join( " ", @cols2 ) . "\n";
        print "\n\n";
      }
      $coldiff = abs($cols1[$i] - $cols2[$i]);
      $minDiffs{$i} = $coldiff if ( ! defined $minDiffs{$i} || $minDiffs{$i} > $coldiff );
      $maxDiffs{$i} = $coldiff if ( ! defined $maxDiffs{$i} || $maxDiffs{$i} < $coldiff );
      print "Row $row diff: Column $i mismatch: $cols1[$i] != $cols2[$i] ( diff = $coldiff, tolerance = $colTolerances{ $i } )\n";
    }
  }
  $row++;
}

# Print summary
#if ( 1 ) 
#{
#  for ( my $i = 0; $i <= 21; $i++ )
#  {
#    print "" . sprintf("%2d  %
#  }
#}
  
1;  
