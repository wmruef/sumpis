#!/usr/bin/perl
##---------------------------------------------------------------------------##
##  File:
##      @(#) sumpis.pl
##  Author:
##      Wendi Ruef   wruef@u.washington.edu
##  Description:
##      This is a program to convert seabird CTD HEX files into
##      aligned and calibrated ASCII data.
##
#******************************************************************************
#*  This software is provided ``AS IS'' and any express or implied            *
#*  warranties, including, but not limited to, the implied warranties of      *
#*  merchantability and fitness for a particular purpose, are disclaimed.     *
#*  In no event shall the authors or the University of Washington be held     *
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

sumpis - process CTD .hex files

=head1 SYNOPSIS

  sumpis [-version] [-format <FORMAT>] [-output_dir <OUTPUT_DIR>]
               [-caldir <CAL_DIR>] [-no_align] [-use_seabird] 
               -config <CONFIG_FILE> <DIR_CONTAINING *.HEX FILES> 

=head1 DESCRIPTION

The options are:

=over 4

=item -version

Displays the version of the program

=item -format

Optional: specifiy the format of the output file

=item -output_dir

Optional: specify output directory for converted file

=item -no_align

Optional: do not align the data during the conversion

=item -caldir

Optional: specify directory for calibration and alignment files

=item -config

Required: configuration file for conversion

=back

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright 2006 Wendi Ruef, University of Washington, School of Oceanography

=head1 AUTHOR

Wendi Ruef <wruef@u.washington.edu>

=cut

#
# Module Dependence
#
use strict;
use Time::Local;
use Getopt::Long;
use Data::Dumper;
use lib "/home/orca/bin/sumpis";
use Seabird::HexCnv;
use stats;
use PrintFormat;
use castTasks;
use discreteSamples;
use fileParser;
#
# Version
#
my $Version = "1.0";

#
# Debuging
#
my $DEBUG = 1;

#
# To align or not to align...that is the question.
my $align_final = 1;

#
# Option processing
#  e.g.
#   -t: Single letter binary option
#   -t=s: String parameters
#   -t=i: Number paramters
#
my @getopt_args = (
                    '-version',       # print out the version and exit
                    '-format=s',
                    '-output=s',
                    '-caldir=s',
                    '-no_align',
                    '-use_seabird',
                    '-config=s',
);

my %options = ();
Getopt::Long::config( "noignorecase", "bundling_override" );
unless ( GetOptions( \%options, @getopt_args ) )
{
  usage();
}

sub usage
{
  print "$0 - $Version\n";
  exec "pod2text $0";
  exit;
}

$align_final = 0 if ( $options{'no_align'} );

if ( $options{'version'} )
{
  print "$Version\n";
  exit;
}

if ( !$options{'config'} )
{
  print "\n\nDude....where's my configuration???\n\n";
  usage();
}

print "\n\nSumpis Seabird CTD HEX file converter\n";
print "Version: $Version\n";
print "Configuration File: " . $options{'config'} . "\n";

#
# ARGV Processing
#
if ( !@ARGV )
{
  usage();
}

##
## RMH: ARGV[0]..ARGV[n] could be files or directories.
##      For now you can just test that they exist and place
##      them in a list for later use.  "-s" file exists and has
##      a non zero size.  "-d" directory exists.
##
my $castDir = $ARGV[ 0 ];
print "Cast Dir: $castDir\n";

# Output format
my $print_format = "default";
if ( $options{'format'} )
{
  $print_format = $options{'format'};
}
print "Output Format: $print_format\n";

# Calibration files directory
my $calDir = $castDir;
if ( $options{'caldir'} )
{
  print "Calibration Files Directory: $options{'caldir'}\n";
  $calDir = $options{'caldir'};
}

#
my $useSeabirdTruncation = 0;
if ( $options{'use_seabird'} )
{
  $useSeabirdTruncation = 1;
}

#
# Read in processing configuration file
#
print "\nReading configuration file...\n";

#
# Open data processing configuration file
open PROCESS_CONF, "<$options{'config'}"
    || die "error! could not open configuration file!\n";

# configuration file format:
#
##
## RMH: Make this into a subroutine which is passed a
##      file name, reads in the parameters and returns
##      them to the main program.
##
# TODO: PASTE FILE FORMAT HERE
#
#
my %processing_parameters = ();

# TODO: fill out rest of valid columns.....
my %valid_column_variables =
    ( "temp" => 1, "sal" => 1, "press" => 1, "cond" => 1 );

# Read file line by line
while ( <PROCESS_CONF> )
{
  next if ( /^\s*\#.*/ );
  next if ( /^\s*$/ );

  # Extract and store location
  if ( /\s*Location\s*=\s*(\S.*)/i )
  {
    $processing_parameters{"location"} = $1;
  }

  # Extract and store latitude
  if ( /\s*Latitude\s*=\s*(\d+\.?\d*)/i )
  {
    $processing_parameters{"latitude"} = $1;
  }

  # Extract and store longitutde
  if ( /\s*Longitude\s*=\s*(\d+\.?\d*)/i )
  {
    $processing_parameters{"longitude"} = $1;
  }

  # Extract and store sensor deployment history
  if ( /\s*sensor_deploy_history\s*=\s*(\S.*)/i )
  {
    $processing_parameters{"sensor_deploy_history"} = $1;
  }

  # Extract and store sensor calibration history
  if ( /\s*sensor_cal_history\s*=\s*(\S.*)/i )
  {
    $processing_parameters{"sensor_cal_history"} = $1;
  }

  # Extract and store discrete calibration data
  if ( /\s*discrete_cal_data\s*=\s*(\S.*)/i )
  {
    $processing_parameters{"discrete_cal_data"} = $1;
  }

  # Extract and store O2 bottle volume data
  if ( /\s*O2_bottle_volume_data\s*=\s*(\S.*)/i )
  {
    $processing_parameters{"O2_bottle_vol_data"} = $1;
  }

  # Extract and store output column order
  if ( /\s*output_column_order\s*=\s*(\S.*)/i )
  {
    # validate output format
    my @fields = split( /\s*,\s*/, lc( $1 ) );
    foreach my $field ( @fields )
    {
      if ( !defined $valid_column_variables{$field} )
      {
        print "Variable $field not valid....\n";
        usage();
      }
    }
    $processing_parameters{"output_column_order"} = [ @fields ];
  }

}
close( PROCESS_CONF );

# DEBUG
#print "processing parameters =".Dumper(\%processing_parameters)."\n";
printProcessingParameters( \%processing_parameters );

my $sensor_cal_file   = $processing_parameters{"sensor_cal_history"};
my $discrete_cal_file = $processing_parameters{"discrete_cal_data"};
my $sensor_deployment_hist_file =
    $processing_parameters{"sensor_deploy_history"};
my $O2_bottle_vol_file = $processing_parameters{"O2_bottle_vol_data"};
my $latitude           = $processing_parameters{"latitude"};

#
# LOOP 1: Read in sensor calibration history and store
#
print "\nReading sensor calibration history...\n";

#
# Parse sensor coefficient file
#
my %sensor_coefficients = parse_sensorCoeff( $sensor_cal_file );

#print "sensor coefficients =".Dumper(\%sensor_coefficients)."\n";

#
# LOOP 2: Read in discrete calibration history and store
#
print "Reading discrete calibration history...\n";

#
# Parse discrete calibration history file
#

my @calibration_samples = parse_discreteO2( $discrete_cal_file );

#print "calibration_samples =".Dumper(\@calibration_samples)."\n";

#
# LOOP 3: Read in sensor deployment history and store
#
print "Reading sensor deployment history...\n";

#
# Parse sensor deployment history
#
my @sensor_deployment = parse_deployHist( $sensor_deployment_hist_file );

#print "sensor deployment history =".Dumper(\@sensor_deployment)."\n";

#
# LOOP 4: Calculate alignment coefficients
#         NOTE: The alignment *could* be calculated for each cast.
#               Currently we use the first cast after a package change
#               to get a constant alignment for all subsequent casts
#               up to the next package change.  I would make this
#               optional so users can convert a single .HEX file
#               without having to have a package history.
#
print "Calculating alignment coefficients...\n";

#
# For each record in the sensor deployment history
## RMH: Make subroutine.
foreach my $deployment_record ( @sensor_deployment )
{
  my $cast_number = $deployment_record->{"CAST"};
  print " - $calDir/$cast_number \n";
  my $alignData = 0;
  my ( $cnv_data, $last_dep_record, $sample_rate ) =
      hexfile2cnv_data(
                        "$calDir/$cast_number", \%sensor_coefficients,
                        \@sensor_deployment,    $latitude,
                        $alignData,             $useSeabirdTruncation
      );

  my @CAST_Scan  = map { $_->{"Scan"} } @{$cnv_data};
  my @CAST_Press = map { $_->{"Press_db"} } @{$cnv_data};
  my @CAST_O2    = map { $_->{"O2_volts"} } @{$cnv_data};
  my @CAST_Temp  = map { $_->{"Temp"} } @{$cnv_data};

  my $O2_align =
      align( \@CAST_Scan, \@CAST_Press, \@CAST_Temp, \@CAST_O2, $sample_rate );
  print "   - O2_align is $O2_align\n";

  $deployment_record->{"O2_align"} = $O2_align;
  my @CAST_Fluor = map { $_->{"Fluor_volts"} } @{$cnv_data};

  if ( @CAST_Fluor )
  {
    my $Fluor_align = align( \@CAST_Scan,  \@CAST_Press, \@CAST_Temp,
                             \@CAST_Fluor, $sample_rate );
    $deployment_record->{"Fluor_align"} = $Fluor_align;
    print "   - Fluor align is $Fluor_align\n";
  }

  my @CAST_NO3 = map { $_->{"NO3"} } @{$cnv_data};
  if ( @CAST_NO3 )
  {
    #print "CAST_NO3 map = " . Dumper( \@CAST_NO3 ) . "\n";
    #print "starting no3 align\n";
    my $NO3_align = align( \@CAST_Scan, \@CAST_Press, \@CAST_Temp,
                           \@CAST_NO3,  $sample_rate );
    $deployment_record->{"NO3_align"} = $NO3_align;
    print "   - NO3 align is $NO3_align\n";
  }

  #print "back from no3 align\n";

#my @CAST_PAR = map { $_->{"PAR"} } @{$cnv_data};
#if ( defined @CAST_PAR ) {
#  #print "CAST_PAR map = " . Dumper( \@CAST_PAR ) . "\n";
#  #print "starting par align\n";
#  my $PAR_align = align( \@CAST_Scan, \@CAST_Press, \@CAST_Temp, \@CAST_PAR, $sample_rate );
#  $deployment_record->{"PAR_align"} = $PAR_align;
#  print "PAR align is $PAR_align\n";
#}
  ##print "back from par align\n";
}

#print "deployment record =".Dumper(\@sensor_deployment)."\n";

#
# LOOP 6: Open CAST.HEX files, convert, align, calibrate and store data in CAST.CAL files
#
print "Converting HEX files...\n";

#
# For each CAST.HEX file in the directory
#
## RMH: Excellent example of code that stays in main.
## RMH: Add code to handle files or directories.
## RMH: Add code to handle -output_dir option
opendir( DIR, "$castDir" ) or die "Can't opendir $castDir dir!!!$!\n";
while ( defined( my $file = readdir( DIR ) ) )
{
#
#
# If file is .HEX extension AND it is greater than 5000 bytes,
# open the file and process
#
# TODO: remove the 5000 byte filter, open the file and print error message
# as to why the file was rejected, i.e. "invalid date" or "too few scans to process".
#
#
#print "statting: $castDir/$file\n";
  my $fileSizeBytes = -s "$castDir/$file";

  #print "filesize of $file: $fileSizeBytes\n";
  if (
       (
            ( $file =~ /ORCA\d+_CAST(\d+)\.HEX/ )
         || ( $file =~ /NPBY\d+_CAST(\d+)\.HEX/ )
       )
       && ( $fileSizeBytes > 5000 )
      )
  {

    # Open CAST file and align ....
    #print "Opening cast $file\n";
    my ( $cnv_data, $last_dep_record, $sample_rate ) =
        hexfile2cnv_data(
                          "$castDir/$file",    \%sensor_coefficients,
                          \@sensor_deployment, $latitude,
                          $align_final,        $useSeabirdTruncation
        );

    #print Dumper ($cnv_data) ."\n";

    #
    # Print data out to file
    #
    my $file_prefix = $file;
    $file_prefix =~ s/\.HEX//;
    if ( $print_format eq 'default' )
    {
      print_default( $cnv_data, "$castDir/$file_prefix" );
      print "   - $file -> $castDir/$file_prefix.DGC\n";
    } elsif ( $print_format eq '19Plus_compare' )
    {
      print19Plus_cnv( $cnv_data, "$castDir/$file_prefix" );
      print "   - $file -> $castDir/$file_prefix.HTA\n";
    } elsif ( $print_format eq '19Plus_custom' )
    {
      print19Plus_custom( $cnv_data, "$castDir/$file_prefix" );
      print "   - $file -> $castDir/$file_prefix.DGC\n";
    } elsif ( $print_format eq '19_compare' )
    {
      print19_cnv( $cnv_data, "$castDir/$file_prefix" );
      print "   - $file -> $castDir/$file_prefix.HTA\n";
    }
  }
}

sub printProcessingParameters
{
  my $paramHash = shift;

  print "Processing Parameters\n";

  # Common single valued parameters
  my @commonParams =
      qw( location longitude latitude sensor_deploy_history discrete_cal_data sensor_cal_history O2_bottle_vol_data );
  foreach my $param ( @commonParams )
  {
    print "  $param: " . $paramHash->{$param} . "\n";
  }

  # Column order is a list parameter
  print "  output_column_order: "
      . join( ", ", @{ $paramHash->{'output_column_order'} } ) . "\n";
}

1;
