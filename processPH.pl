#!/usr/bin/perl
##---------------------------------------------------------------------------##
##  File:
##      @(#) processPH.pl
##  Author:
##      Wendi Ruef   wruef@uw.edu
##  Description:
##      A script to parse data files from the Satlantic SeaFET pH sensor and
##      recalculate pH based on surface salinity.
##
##  See LICENSE for conditions of use.
## The call in corca_daily
## ./processPH.pl /home/orca/HoodCanal/programs/surface365_CarrInlet.txt configurationFiles/auxiliary_deployment_history_carrinlet.txt ...
## configurationFiles/sensor_calibration_data.txt /home/orca/CarrInlet/data_queue
## rm /home/orca/CarrInlet/data_queue/*.AUX
##
##
#******************************************************************************

#
# TODO:
#	- reconcile GMT from pH data with localtime from CTD surface data
#
#
# Module Dependence
#
use strict;
use Time::Local;
use Data::Dumper;
use lib "/home/orca/bin/data_goddess";
use dataTasks;
use stats;
use fileParser;
use Seabird::HexCnv;
##
## Main code
##

my $surface365_file                 = shift;
my $aux_sensor_deployment_hist_file = shift;
my $sensor_cal_file                 = shift;
my $dataDir                         = shift;

#
# Retrieve surface salinity for buoy location
#
my $sal_default     = 29.000;
my @surface365_data = parse_surface365( $surface365_file );

#print "surface data = ".Dumper(\@surface365_data)."\n";

#
# Parse sensor deployment history
#
my @aux_sensor_deployment =
    parse_AuxDeployHist( $aux_sensor_deployment_hist_file );

#print "aux sensor deployment history =".Dumper(\@aux_sensor_deployment)."\n";

#
# Parse sensor coefficient file
#

my %sensor_coefficients = parse_sensorCoeff( $sensor_cal_file );

#print "sensor coefficients =".Dumper(\%sensor_coefficients)."\n";

#
# Start Directory loop
#

opendir( DIR, "$dataDir" ) or die "Can't opendir $dataDir dir!!!!!\n";
while ( defined( my $file = readdir( DIR ) ) )
{    # while - loop 1
  my $fileSizeBytes = -s "$dataDir/$file";
  if (
       (
            ( $file =~ /(ORCA\d+_AUX\d+)\.AUX/ )
         || ( $file =~ /(NPBY\d+_AUX\d+)\.AUX/ )
       )
       && ( $fileSizeBytes > 1000 )
      )
  {    # if - loop 2
    my $dataFile = $1;

    print "dataFile = $dataFile\n";
    my $fileYear   = substr( $dataFile, 9,  4 );
    my $fileMonth  = substr( $dataFile, 13, 2 ) - 1;
    my $fileDay    = substr( $dataFile, 15, 2 );
    my $fileHour   = substr( $dataFile, 17, 2 );
    my $fileMinute = substr( $dataFile, 19, 2 );
    my $fileTime =
        timelocal( 0, $fileMinute, $fileHour, $fileDay, $fileMonth, $fileYear );

    #print "my fileTime = $fileTime\n";
    #
    # Extract matching sensor deployment and coefficient records
    #
    my $last_deployment_record;
    foreach my $aux_deployment_record ( @aux_sensor_deployment )
    {
      ##print "$aux_deployment_record->{'time'}\n";
      if ( $aux_deployment_record->{"time"} > $fileTime )
      {
        last;
      }
      $last_deployment_record = $aux_deployment_record;
    }
    if ( $last_deployment_record == 0 )
    {
      print "argh! couldn't find a deployment record\n";
    }

    #print Dumper($last_deployment_record);

    my $PH_model                   = $last_deployment_record->{"PH_model"};
    my $PH_SN                      = $last_deployment_record->{"PH_SN"};
    my $last_PH_coefficient_record = 0;
    foreach my $PH_coefficient_record (
                                @{ $sensor_coefficients{$PH_model}->{$PH_SN} } )
    {
      if ( $PH_coefficient_record->{"PH_cal_date"} > $fileTime )
      {
        last;
      }
      $last_PH_coefficient_record = $PH_coefficient_record;
    }
    if ( $last_PH_coefficient_record == 0 )
    {
      print "argh! couldn't find a PH coefficient record\n";
    }
    my $PH_coefficients = $last_PH_coefficient_record;

    #print Dumper($PH_coefficients);

    #
    # Find archive data range
    #
    open FILE_IN,  "<$dataDir/$dataFile.AUX";
    open FILE_OUT, ">$dataDir/$dataFile.PH"
        or die "Can't open $dataFile.PH!!!!!\n";

    while ( <FILE_IN> )
    {    # while - loop 3

      next if ( /#.*/ );

      my @cols    = split( /,/ );
      my $date    = $cols[ 1 ];
      my $time    = $cols[ 2 ];
      my $intpH   = $cols[ 3 ];
      my $extpH   = $cols[ 4 ];
      my $temp    = $cols[ 5 ];
      my $intVolt = $cols[ 10 ];
      my $extVolt = $cols[ 11 ];

      my $year = substr( $date, 0, 4 );
      my $doy = substr( $date, 4 );
      my $month = 0;
      my $day   = 0;
      ( $month, $day ) = doy2date( $year, $doy );

      my $hour   = int( $time );
      my $minute = int( ( $time - $hour ) * 60 );
      my $second = int( ( ( ( $time - $hour ) * 60 ) - $minute ) * 60 );

      my $pHtime = timegm( $second, $minute, $hour, $day, $month, $year );
      my $yearday_LOCAL = yearday2000( $pHtime );

      #
      # Find closest measured surface salinity
      #

      my @yearday = map { $_->{"yearday"} } @surface365_data;
      my $closestYearday = closest( $yearday_LOCAL, @yearday );

      my $last_surface_sample = 0;
      my $sal;
      foreach my $surface_sample ( @surface365_data )
      {
        if ( $surface_sample->{"yearday"} == $closestYearday )
        {
          last;
        }
        $last_surface_sample = $surface_sample;
        $sal                 = $last_surface_sample->{'sal'};
      }
      if ( $last_surface_sample == 0 )
      {
        print
            "argh! couldn't find a matching salinity sample...using default!\n";
        $sal = $sal_default;
      }
      my $pH_int = volts2pH( "INT", $temp, $sal, $intVolt, $PH_coefficients );
      my $pH_ext = volts2pH( "EXT", $temp, $sal, $extVolt, $PH_coefficients );

      print FILE_OUT
          "$yearday_LOCAL\t$temp\t$sal\t$intVolt\t$extVolt\t$pH_int\t$pH_ext\n";
    }    # close while - loop 3

    close FILE_IN;
    close FILE_OUT;

  }    # close if - loop 2

}    # close while - loop 1

sub closest
{
  my $val = shift;
  my @list = sort { abs( $a - $val ) <=> abs( $b - $val ) } @_;
  $list[ 0 ];
}

