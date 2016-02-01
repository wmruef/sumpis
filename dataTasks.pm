#!/usr/bin/perl
package dataTasks;

use strict;
use Time::Local;
use Data::Dumper;
use fileParser;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA         = qw(Exporter);
@EXPORT      = qw(buildSensorDeployHist yearday2000 doy2date leap);
@EXPORT_OK   = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* buildSensorDeployHist: builds deployment record for a     *#
#* single sensor                                             *#
#*							     *#
#* Input to function: deployment record, sensor              *#
#* Returns to main: deployment history for sensor            *#
#*************************************************************#
sub buildSensorDeployHist
{
  my $sensor_deployment_hist_file = shift;
  my $sensor                      = shift;

  my @sensor_deployment_history;
  my $deployment_index = 0;

  #
  # Parse sensor deployment history
  #
  my @sensor_deployment = parse_deployHist( $sensor_deployment_hist_file );

  foreach my $deployment_record ( @sensor_deployment )
  {
    my $sensor_model = "-555";
    my $sensor_SN    = "-555";
    foreach my $dep_key ( keys( %{$deployment_record} ) )
    {
      if ( $dep_key =~ /V(\d)_type/ )
      {
        my $index = $1;
        if ( $deployment_record->{$dep_key} eq $sensor )
        {
          $sensor_model = $deployment_record->{ "V" . $index . "_model" };
          $sensor_SN    = $deployment_record->{ "V" . $index . "_SN" };
        }    # END if dep key = V
      }    # END if dep key == sensor
    }    # END foreach dep key
    $sensor_deployment_history[ $deployment_index ]->{'time'} =
        $deployment_record->{'time'};
    $sensor_deployment_history[ $deployment_index ]->{'cast'} =
        $deployment_record->{'CAST'};
    $sensor_deployment_history[ $deployment_index ]->{'sensor_model'} =
        $sensor_model;
    $sensor_deployment_history[ $deployment_index ]->{'sensor_SN'} = $sensor_SN;
    $deployment_index++;
  }    # END foreach deployment_record

  # DEBUG
  #print Dumper(\@sensor_deployment_history);

  return @sensor_deployment_history;

}    # END buildSesnorDeployHist subroutine

#*************************************************************#
#* yearday2000: converts perl time into yeardays from 2000   *#
#* (yearday 1 = 01/01/2000 00:00                             *#
#*                                                           *#
#* Input to function: perl time                              *#
#* Returns to main: yearday                                  *#
#*************************************************************#
sub yearday2000
{

  my $perlTime = shift;

  my $yeardayZero = timelocal( 0, 0, 0, 31, 12 - 1, 1999 );

  my $yearday;

  # Convert UNIX date format into fields
  my (
       $second1, $minute1, $hour1, $day1, $month1,
       $year1,   $wday1,   $yday1, $isdst1
  ) = localtime( $yeardayZero );

  # Convert UNIX date format into fields
  my (
       $second2, $minute2, $hour2, $day2, $month2,
       $year2,   $wday2,   $yday2, $isdst2
  ) = localtime( $perlTime );

  if ( $year2 == $year1 )
  {
    $yearday = $yday2 - $yday1;
  } else
  {
    $yearday = daysInYear( $year1 ) - ( $yday1 + 1 );
    for ( my $i = $year1 + 1 ; $i < $year2 ; $i++ )
    {
      $yearday += daysInYear( $i );
    }
    $yearday += ( $yday2 + 1 );
  }

  my $dayfrac1 =
      ( $hour1 / 24 ) + ( $minute1 / 60 / 24 ) + ( $second1 / 60 / 60 / 24 );
  my $dayfrac2 =
      ( $hour2 / 24 ) + ( $minute2 / 60 / 24 ) + ( $second2 / 60 / 60 / 24 );
  my $dayfracdiff = $dayfrac2 - $dayfrac1;
  $yearday += ( $dayfracdiff );

  return ( $yearday );

}    # END yearday2000 subroutine

sub daysInYear
{
  my $year = shift;

  my @fields = localtime( timelocal( 1, 0, 0, 31, 11, $year ) );
  return ( $fields[ 7 ] + 1 );
}

sub doy2date
{
  my $year = shift;
  my $doy  = shift;
  my @months_doy;
  my $month = 0;
  my $day   = 0;

  if ( leap( $year ) == 1 )
  {
    @months_doy = ( 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 );
  } else
  {
    @months_doy = ( 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 );
  }

  for ( my $i = 0 ; $i < 13 ; $i++ )
  {
    if ( $doy <= $months_doy[ $i ] )
    {
      $month = $i;
      if ( $i == 0 )
      {
        $day = $doy;
      } else
      {
        $day = $doy - $months_doy[ $i - 1 ];
      }
      last;
    }
  }

  return ( $month, $day );
}

sub leap
{
  my $y = shift;
  return 0 unless $y % 4 == 0;
  return 1 unless $y % 100 == 0;
  return 0 unless $y % 400 == 0;
  return 1;
}

1;
