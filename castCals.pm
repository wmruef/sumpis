#!/usr/bin/perl
package castCals;

use strict;
use Time::Local;
use Data::Dumper;
use stats;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA         = qw(Exporter);
@EXPORT      = qw(align_CTD);
@EXPORT_OK   = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* align_CTD: calculates the alignment coefficients for each *#
#* auxiliary sensor (O2, Fluor, NO3, PAR)                    *#
#*							     *#
#* Input to function: sensor deployment record               *#
#* Returns to main: sensor deployment record with alignments *#
#*************************************************************#
sub align_CTD
{

  #
  # For each record in the sensor deployment history
  foreach my $deployment_record ( @sensor_deployment )
  {
    my $cast_number = $deployment_record->{"CAST"};
    print "$calDir/$cast_number \n";

    my $useSeabirdTruncation = 1;
    my $alignData            = 0;
    my ( $cnv_data, $last_dep_record, $sample_rate ) =
        hexfile2cnv_data(
                          "$calDir/$cast_number", \%sensor_coefficients,
                          \@sensor_deployment,    $latitude,
                          $alignData,             $useSeabirdTruncation
        );

    #print "Back...and " . Dumper($cnv_data) . "\n";
    my @CAST_Scan  = map { $_->{"Scan"} } @{$cnv_data};
    my @CAST_Press = map { $_->{"Press_db"} } @{$cnv_data};
    my @CAST_O2    = map { $_->{"O2_volts"} } @{$cnv_data};
    my @CAST_Temp  = map { $_->{"Temp"} } @{$cnv_data};

    #print Dumper( \@CAST_Scan) ."\n";

    #print "working on record $cast_number\n";
    my $O2_align = align( \@CAST_Scan, \@CAST_Press, \@CAST_Temp, \@CAST_O2,
                          $sample_rate );

    #print "back from O2_align\n";
    print "O2_align is $O2_align\n";
    $deployment_record->{"O2_align"} = $O2_align;

    my @CAST_Fluor = map { $_->{"Fluor_volts"} } @{$cnv_data};

    #print "Fluor: ".Dumper(\@CAST_Fluor) ."\n";
    if ( defined @CAST_Fluor )
    {
      #print "CAST_Fluor map = " . Dumper( \@CAST_Fluor ) . "\n";
      #print "starting fluor align\n";
      my $Fluor_align = align( \@CAST_Scan,  \@CAST_Press, \@CAST_Temp,
                               \@CAST_Fluor, $sample_rate );
      $deployment_record->{"Fluor_align"} = $Fluor_align;
      print "Fluor align is $Fluor_align\n";
    }

    #print "back from fluor align\n";

    my @CAST_NO3 = map { $_->{"NO3"} } @{$cnv_data};
    if ( defined @CAST_NO3 )
    {
      #print "CAST_NO3 map = " . Dumper( \@CAST_NO3 ) . "\n";
      #print "starting no3 align\n";
      my $NO3_align = align( \@CAST_Scan, \@CAST_Press, \@CAST_Temp,
                             \@CAST_NO3,  $sample_rate );
      $deployment_record->{"NO3_align"} = $NO3_align;
      print "NO3 align is $NO3_align\n";
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

}

# END align_CTD subroutine

1;
