#!/usr/bin/perl
package discreteSamples;

use strict;
use Time::Local;
use Data::Dumper;
use stats;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA         = qw(Exporter);
@EXPORT      = qw(Fluor2Chlr Wink2Oxy);
@EXPORT_OK   = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* Fluor2Chlr : Calculates chlorophyll concentrations of a   *#
#* discrete record of chlorophyll extractions                *#
#*                                                           *#
#* Input to function: chlorophyll extraction record          *#
#* Returns to main: chlorophyll extraction record, with      *#
#* concentrations (in mg/m^3) added for each sample          *#
#*************************************************************#
sub Fluor2Chlr
{
  my $sample_data = shift;

  my $Chlr                = 0;
  my $i                   = 0;
  my $sample_record_index = $#{ $sample_data->{"samples"} };
  my $K                   = 0;

  # Kx equation: (Lini / (avg_standards)) * K
  if ( exists $sample_data->{"std"} )
  {
    #print "sample standard is: ". $sample_data->{"std"} ."\n";
    $K = ( $sample_data->{"Lini"} / $sample_data->{"std"} ) *
        $sample_data->{"Kx"};
  } else
  {
    #print "standard not defined!!!\n";
    $K = $sample_data->{"Kx"};
  }

# Chlorophyll equation: Chlr (mg/m^#) = Kx * ( Fm/(Fm -1) ) * ( (Fo - blk) - (Fa - blk) ) * (vol_extract/vol_sampled) * Dilution_factor

  for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
  {
    $Chlr = $K *
        $sample_data->{"Fm"} /
        ( $sample_data->{"Fm"} - 1 ) *
        (
          (
            $sample_data->{"samples"}[ $i ]->{"Fo"} -
                $sample_data->{"samples"}[ $i ]->{"blank"}
          ) - (
                $sample_data->{"samples"}[ $i ]->{"Fa"} -
                    $sample_data->{"samples"}[ $i ]->{"blank"}
          )
        ) *
        ( $sample_data->{"samples"}[ $i ]->{"volExtract"} /
          $sample_data->{"samples"}[ $i ]->{"volSample"} ) *
        $sample_data->{"samples"}[ $i ]->{"Dilution"};

    $sample_data->{"samples"}[ $i ]->{"Chlr"} = $Chlr;
  }

  return $sample_data;

}

# END Fluor2Chlr subroutine

#*************************************************************#
#* Wink2Oxy : Calculates oxygen concentrations of a discrete *#
#* oxygen sample record of winkler titrations                *#
#* Input to function: oxygen sample record                   *#
#* Returns to main: oxygen sample record, with               *#
#* concentrations (in ml/l) added for each sample            *#
#*************************************************************#
sub Wink2Oxy
{
  my $sample_data = shift;

  my $O2                  = 0;
  my $i                   = 0;
  my $sample_record_index = $#{ $sample_data->{"samples"} };

#Winkler equation: O2(ml/l)= (((Corr_sample - blank) * pipette_vol * stnd_nrml * 5598)/((Corr_stnd - blank) * (bot_vol - 2))) - 0.018;
  my $i = 0;
  for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
  {
    #print "Sample data: \n";
    #print "samp_ml: " . $sample_data->{"samples"}[ $i ]->{"samp_ml"} . "\n";
    #print "blnk: " . $sample_data->{"blnk"} . "\n";
    #print "KIO3_ml: " . $sample_data->{"KIO3_ml"} . "\n";
    #print "stnd_nrml: " . $sample_data->{"stnd_nrml"} . "\n";
    #print "stnd_ml: " . $sample_data->{"stnd_ml"} . "\n";
    #print "btlVol: " . $sample_data->{"samples"}[ $i ]->{"btlVol"} . "\n";
    $O2 = (
       (
         (
           $sample_data->{"samples"}[ $i ]->{"samp_ml"} - $sample_data->{"blnk"}
         ) * $sample_data->{"KIO3_ml"} * $sample_data->{"stnd_nrml"} * 5598
       ) / (
             ( $sample_data->{"stnd_ml"} - $sample_data->{"blnk"} ) *
                 ( $sample_data->{"samples"}[ $i ]->{"btlVol"} - 2 )
       )
    ) - 0.018;
    $sample_data->{"samples"}[ $i ]->{"O2_ml"} = $O2;
  }

  return $sample_data;
}

# END Wink2Oxy subroutine

1;
