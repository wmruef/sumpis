#!/usr/bin/perl
package fileParser;

use strict;
use Time::Local;
use Data::Dumper;
use stats;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA = qw(Exporter);
@EXPORT =
    qw(parse_btlVol parse_discreteChl parse_discreteNut parse_discreteO2 parse_sensorCoeff parse_deployHist parse_AuxDeployHist parse_DGC parse_surface365);
@EXPORT_OK = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

## TODO: add validation code to all parsers!!!!!

#*************************************************************#
#* parse_btlVol :                                            *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: bottle volume records                    *#
#*************************************************************#
sub parse_btlVol
{
  my $bottle_volumes_file = shift;

  #
  # Open bottle volumes data file
  #
  open BTL_VOL_DATA, "<$bottle_volumes_file"
      || die "error! could not open bottle volumes data file!\n";

  # bottle volumes data file format:
  # [01/01/05 12:00]
  # 131=125
  #
  # Define variables
  my @bottle_volumes     = ();
  my $btl_index          = 0;
  my $sub_btl_index      = 0;
  my $found_first_record = 0;

  # Read data line by line
  while ( <BTL_VOL_DATA> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    # Extract time
    if ( /^\s*\[\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)\s*\]/ )
    {

      # Set incrementation
      if ( $found_first_record == 1 )
      {
        $btl_index++;
        $sub_btl_index = 0;
      }
      $found_first_record = 1;

      # Extract and store time
      my $time = timelocal( 0, $5, $4, $2, $1 - 1, $3 );
      $bottle_volumes[ $btl_index ]->{"time"} = $time;
    }

    # Extract and store bottle number and volume
    if ( /\s*(\d+)\s*=\s*(\d+\.?\d*)/ )
    {
      $bottle_volumes[ $btl_index ]->{$1} = $2;
      $sub_btl_index++;
    }
  }
  close( BTL_VOL_DATA );

  #print "bottle_volumes =".Dumper(\@bottle_volumes)."\n";

  return @bottle_volumes;

}

# END parse_btlVol subroutine

#*************************************************************#
#* parse_discreteChl : Parse the file containing discrete    *#
#* sample information for chlorphyll extractions             *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: chlorophyll sample records               *#
#*************************************************************#
sub parse_discreteChl
{

  my $discrete_chl_file = shift;

  #
  # Open discrete calibration data file
  open DISC_CHL_DATA, "<$discrete_chl_file"
      || die "error! could not open calibration data file!\n";

# discrete_calibration_data file format:
# [01/01/2005 12:00]
# Kx=0.099394 std1=186.9 std2=184.6 std3=185.8 Fm=2.09226 Lini=190.7 CAST_file=ORCA2_CAST0001.HEX
# samp=depth Vol_samp Vol_extract Blnk Fo Fa Dilution
# samp=30 50 10 0 561 307 1
#
# Define variables
  my @chl_samples        = ();
  my $chl_index          = 0;
  my $sample_index       = 0;
  my $found_first_record = 0;

  # Read data line by line
  while ( <DISC_CHL_DATA> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    # Extract time
    if ( /^\s*\[\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)\s*\]/ )
    {

      # Set incrementation
      if ( $found_first_record == 1 )
      {
        $chl_index++;
        $sample_index = 0;
      }
      $found_first_record = 1;

      # Extract and store time
      my $time = timelocal( 0, $5, $4, $2, $1 - 1, $3 );
      $chl_samples[ $chl_index ]->{"time"} = $time;
    }

    # Extract and store cast type
    if ( /\s*CAST_type\s*=\s*(\S+)/ )
    {
      $chl_samples[ $chl_index ]->{"cast_type"} = $1;
    }

    # Extract and store Kx value
    if ( /\s*Kx\s*=\s*(\d+\.?\d*)/ )
    {
      $chl_samples[ $chl_index ]->{"Kx"} = $1;
    }

    # Extract and store fluorometer reading from standard
    if ( /\s*std\s*=\s*(\d+\.?\d*)/ )
    {
      $chl_samples[ $chl_index ]->{"std"} = $1;
    }

    # Extract and store Fo/Fa Max value
    if ( /\s*Fm\s*=\s*(\d+\.?\d*)/ )
    {
      $chl_samples[ $chl_index ]->{"Fm"} = $1;
    }

    # Extract and store Lini value
    if ( /\s*Lini\s*=\s*(\d+\.?\d*)/ )
    {
      $chl_samples[ $chl_index ]->{"Lini"} = $1;
    }

    # Extract and store CAST number
    if ( /\s*CAST_file\s*=\s*(\S+)/ )
    {
      $chl_samples[ $chl_index ]->{"CAST_file"} = $1;
    }

    # Extract and store sample depth, volume sampled, volume extracted,
    # blank, Fo reading, Fa reading, dilution factor
    if (
/\s*samp\s*=\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\S*\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s*(\S*)/
        )
    {
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"depth"} =
          $1;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"volSample"}
          = $2;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"volExtract"}
          = $3;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"blank"} =
          $4;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"Fo"} = $5;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"Fa"} = $6;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"Dilution"}
          = $7;
      $chl_samples[ $chl_index ]->{"samples"}->[ $sample_index ]->{"discFile"}
          = $8;
      $sample_index++;
    }

  }
  close( DISC_CHL_DATA );

  #print "chl_samples =".Dumper(\@chl_samples)."\n";

  return @chl_samples;
}

# END parse_discreteChl subroutine

#*************************************************************#
#* parse_discreteNut : Parse the file containing discrete    *#
#* sample information for nutrients                          *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: nutrient sample records                  *#
#*************************************************************#
sub parse_discreteNut
{

  my $discrete_nut_file = shift;

  #
  # Open discrete calibration data file
  open DISC_NUT_DATA, "<$discrete_nut_file"
      || die "error! could not open calibration data file!\n";

  # discrete_calibration_data file format:
  # [01/01/2005 12:00]
  # samp=depth PO4 SiO4 NO3 NO2 NH4
  #
  # Define variables
  my @nut_samples        = ();
  my $nut_index          = 0;
  my $sample_index       = 0;
  my $found_first_record = 0;

  # Read data line by line
  while ( <DISC_NUT_DATA> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    # Extract time
    if ( /^\s*\[\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)\s*\]/ )
    {

      # Set incrementation
      if ( $found_first_record == 1 )
      {
        $nut_index++;
        $sample_index = 0;
      }
      $found_first_record = 1;

      # Extract and store time
      my $time = timelocal( 0, $5, $4, $2, $1 - 1, $3 );
      $nut_samples[ $nut_index ]->{"time"} = $time;
    }

    # Extract and store cast type
    if ( /\s*CAST_type\s*=\s*(\S+)/ )
    {
      $nut_samples[ $nut_index ]->{"cast_type"} = $1;
    }

    # Extract and store CAST number
    if ( /\s*CAST_file\s*=\s*(\S+)/ )
    {
      $nut_samples[ $nut_index ]->{"CAST_file"} = $1;
    }

    # Extract and store sample depth, PO4, SiO4, NO3, NO2, NH4
    if (
/\s*samp\s*=\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\S*\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s*(\S*)/
        )
    {
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"depth"} =
          $1;
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"PO4"}  = $2;
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"SiO4"} = $3;
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"NO3"}  = $4;
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"NO2"}  = $5;
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"NH4"}  = $6;
      $nut_samples[ $nut_index ]->{"samples"}->[ $sample_index ]->{"discFile"}
          = $7;
      $sample_index++;
    }
  }
  close( DISC_NUT_DATA );

  #print "nut_samples =".Dumper(\@nut_samples)."\n";

  return @nut_samples;
}

# END parse_discreteNut subroutine

#*************************************************************#
#* parse_discreteO2 : Parse the file containing discrete     *#
#* sample information for oxygen samples and titrations      *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: oxygen sample records                    *#
#*************************************************************#
sub parse_discreteO2
{

  my $discrete_cal_file = shift;

  #
  # Open discrete calibration data file
  open DISC_CAL_DATA, "<$discrete_cal_file"
      || die "error! could not open calibration data file!\n";

# discrete_calibration_data file format:
# [01/01/05 12:00]
# stnd_ml=1.234 stnd_nrml=0.0250 blnk=0.000 KIO3_ml=4.997 CAST_file=ORCA2_CAST0001.HEX
# samp=30 101 1.000
#
# Define variables
  my @calibration_samples = ();
  my $cal_index           = 0;
  my $sample_index        = 0;
  my $found_first_record  = 0;

  # Read data line by line
  while ( <DISC_CAL_DATA> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    # Extract time
    if ( /^\s*\[\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)\s*\]/ )
    {

      # Set incrementation
      if ( $found_first_record == 1 )
      {
        $cal_index++;
        $sample_index = 0;
      }
      $found_first_record = 1;

      # Extract and store time
      my $time = timelocal( 0, $5, $4, $2, $1 - 1, $3 );
      $calibration_samples[ $cal_index ]->{"time"} = $time;
    }

    # Extract and store cast type
    if ( /\s*CAST_type\s*=\s*(\S+)/ )
    {
      $calibration_samples[ $cal_index ]->{"cast_type"} = $1;
    }

    # Extract and store mL titrant for standard
    if ( /\s*stnd_ml\s*=\s*(\d+\.?\d*)/ )
    {
      $calibration_samples[ $cal_index ]->{"stnd_ml"} = $1;
    }

    # Extract and store standard concentration
    if ( /\s*stnd_nrml\s*=\s*(\d+\.?\d*)/ )
    {
      $calibration_samples[ $cal_index ]->{"stnd_nrml"} = $1;
    }

    # Extract and store titration blank
    if ( /\s*blnk\s*=\s*(\d+\.?\d*)/ )
    {
      $calibration_samples[ $cal_index ]->{"blnk"} = $1;
    }

    # Extract and store volume of standard
    if ( /\s*KIO3_ml\s*=\s*(\d+\.?\d*)/ )
    {
      $calibration_samples[ $cal_index ]->{"KIO3_ml"} = $1;
    }

    # Extract and store CAST number
    if ( /\s*CAST_file\s*=\s*(\S+)/ )
    {
      $calibration_samples[ $cal_index ]->{"CAST_file"} = $1;
    }

# Extract and store sample depth, bottle number, ml titrant, and discrete file name
    if ( /\s*samp\s*=\s*(\d+)\s+(\d+)\s+(\d+\.?\d*)\s*(\S*)/ )
    {
      $calibration_samples[ $cal_index ]->{"samples"}->[ $sample_index ]
          ->{"depth"} = $1;
      $calibration_samples[ $cal_index ]->{"samples"}->[ $sample_index ]
          ->{"bottle"} = $2;
      $calibration_samples[ $cal_index ]->{"samples"}->[ $sample_index ]
          ->{"samp_ml"} = $3;
      $calibration_samples[ $cal_index ]->{"samples"}->[ $sample_index ]
          ->{"discFile"} = $4;
      $sample_index++;
    }
  }
  close( DISC_CAL_DATA );

  #print "calibration_samples =".Dumper(\@calibration_samples)."\n";

  return @calibration_samples;
}

# END parse_discreteO2 subroutine

#*************************************************************#
#* parse_sensorCoeff : Parse the file containing sensor      *#
#* coefficients, as reported by the manufacturer             *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: sensor coefficient records                *#
#*************************************************************#
sub parse_sensorCoeff
{

  my $sensor_cal_file = shift;

  #
  # Open sensor calibration data file
  open SENSOR_CAL_DATA, "<$sensor_cal_file"
      || die "error! could not open calibration data file!\n";

# sensor_calibration_data file format:
# EX:
# Sensor=SBE19 SN=2835
# CTD_cal_date=[01/01/04]
# cond_g=-4.16533426 cond_h=4.96296919e-01 cond_i=1.54601169e-03 cond_j=-4.7723728e-05 cond_CPcor=-9.57e-08 cond_CTcor=3.25e-06
# temp_g=4.21059973e-03 temp_h=5.97017997e-04 temp_i=3.80929083e-06 temp_j=-1.85656400e-06 temp_f0=1000.00
# press_M=-0.06526 press_B=248.60 press_A0=248.24555 press_A1=-6.524518e-02 press_A2=5.430179E-08
#
# Define variables
  my %sensor_coefficients = ();
  my $sensor_model        = 0;
  my $sensor_SN           = 0;
  my $sample_index        = 0;

  # Read data line by line
  while ( <SENSOR_CAL_DATA> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    #
    # Identify sensor
    #
    if ( /\s*Sensor\s*=\s*(\S+)\s+SN=(\S+)/ )
    {

      #$sensor_coefficients{$1}->{$2};
      $sensor_model = $1;
      $sensor_SN    = $2;
      $sample_index = 0;
    }

    #
    # Extract time of cal record
    #
    # Identify sensor and store time
    if ( /^\s*CTD_cal_date=\s*\[\s*(\d+)\/(\d+)\/(\d+)\]/ )
    {
      my $time = timelocal( 0, 0, 0, $2, $1 - 1, $3 );
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"CTD_cal_date"} = $time;
    } elsif ( /^\s*O2_cal_date=\s*\[\s*(\d+)\/(\d+)\/(\d+)\]/ )
    {
      my $time = timelocal( 0, 0, 0, $2, $1 - 1, $3 );
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cal_date"} = $time;
    } elsif ( /^\s*Chlor_cal_date=\s*\[\s*(\d+)\/(\d+)\/(\d+)\]/ )
    {
      my $time = timelocal( 0, 0, 0, $2, $1 - 1, $3 );
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cal_date"} = $time;
    } elsif ( /^\s*PAR_cal_date=\s*\[\s*(\d+)\/(\d+)\/(\d+)\]/ )
    {
      my $time = timelocal( 0, 0, 0, $2, $1 - 1, $3 );
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cal_date"} = $time;
    } elsif ( /^\s*NO3_cal_date=\s*\[\s*(\d+)\/(\d+)\/(\d+)\]/ )
    {
      my $time = timelocal( 0, 0, 0, $2, $1 - 1, $3 );
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cal_date"} = $time;
    } elsif ( /^\s*PH_cal_date=\s*\[\s*(\d+)\/(\d+)\/(\d+)\]/ )
    {
      my $time = timelocal( 0, 0, 0, $2, $1 - 1, $3 );
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cal_date"} = $time;

    }    #
         # Extract calibration coefficients
         #
    if (
/\s*cond_g=\s*(\S*\d+)\s+cond_h=\s*(\S*\d+)\s+cond_i=\s*(\S*\d+)\s+cond_j=\s*(\S*\d+)\s+cond_CPcor=\s*(\S*\d+)\s+cond_CTcor=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cond_g"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cond_h"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cond_i"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cond_j"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cond_CPcor"} = $5;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"cond_CTcor"} = $6;
    }
    if (
/\s*temp_g=\s*(\S*\d+)\s+temp_h=\s*(\S*\d+)\s+temp_i=\s*(\S*\d+)\s+temp_j=\s*(\S*\d+)\s+temp_f0=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_g"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_h"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_i"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_j"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_f0"} = $5;
    }
    if (
/\s*temp_a0=\s*(\S*\d+)\s+temp_a1=\s*(\S*\d+)\s+temp_a2=\s*(\S*\d+)\s+temp_a3=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_a0"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_a1"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_a2"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"temp_a3"} = $4;
    }
    if (
/\s*press_M=\s*(\S*\d+)\s+press_B=\s*(\S*\d+)\s+press_A0=\s*(\S*\d+)\s+press_A1=\s*(\S*\d+)\s+press_A2=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_M"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_B"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_A0"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_A1"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_A2"} = $5;
      $sample_index++;
    }
    if (
/\s*press_PA0=\s*(\S*\d+)\s+press_PA1=\s*(\S*\d+)\s+press_PA2=\s*(\S*\d+)\s+press_PTempPA0=\s*(\S*\d+)\s+press_PTempPA1=\s*(\S*\d+)\s+press_PTempPA2=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PA0"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PA1"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PA2"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTempPA0"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTempPA1"} = $5;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTempPA2"} = $6;
    }
    if (
/\s*press_PTCA0=\s*(\S*\d+)\s+press_PTCA1=\s*(\S*\d+)\s+press_PTCA2=\s*(\S*\d+)\s+press_PTCB0=\s*(\S*\d+)\s+press_PTCB1=\s*(\S*\d+)\s+press_PTCB2=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTCA0"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTCA1"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTCA2"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTCB0"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTCB1"} = $5;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"press_PTCB2"} = $6;
      $sample_index++;
    }
    if (
/\s*O2_Soc=\s*(\S*\d+)\s+O2_Boc=\s*(\S*\d+)\s+O2_Voffset=\s*(\S*\d+)\s+O2_TCor=\s*(\S*\d+)\s+O2_PCor=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_Soc"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_Boc"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_Voffset"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_TCor"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_PCor"} = $5;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"eqn"} = '2';
      $sample_index++;
    }
    if (
/\s*O2_Soc=\s*(\S*\d+)\s+O2_Voffset=\s*(\S*\d+)\s+O2_tau20=\s*(\S*\d+)\s+O2_A=\s*(\S*\d+)\s+O2_B=\s*(\S*\d+)\s+O2_C=\s*(\S*\d+)\s+O2_E=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_Soc"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_Voffset"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_tau20"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_A"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_B"} = $5;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_C"} = $6;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"O2_E"} = $7;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"eqn"} = '3';
      $sample_index++;
    }
    if (
/\s*Chlor_offset=\s*(\S*\d+)\s+Chlor_scale_factor=\s*(\S*\d+)\s+Turb_offset=\s*(\S*\d+)\s+Turb_scale_factor=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"Chlor_offset"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"Chlor_scale_factor"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"Turb_offset"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"Turb_scale_factor"} = $4;
      $sample_index++;
    }
    if ( /\s*Chlor_offset=\s*(\S*\d+)\s+Chlor_scale_factor=\s*(\S*\d+)$/ )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"Chlor_offset"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"Chlor_scale_factor"} = $2;
      $sample_index++;
    }

    if (
/\s*PAR_m=\s*(\S*\d+)\s+PAR_b=\s*(\S*\d+)\s+PAR_cal_constant=\s*(\S*\d+)\s+PAR_multiplier=\s*(\S*\d+)\s+PAR_offset=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PAR_m"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PAR_b"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PAR_cal_constant"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PAR_multiplier"} = $4;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PAR_offset"} = $5;
      $sample_index++;
    }
    if ( /\s*NO3_A0=\s*(\S*\d+)\s+NO3_A1=\s*(\S*\d+)/ )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"NO3_A0"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"NO3_A1"} = $2;
      $sample_index++;
    }

    if (
/\s*PH_K0i=\s*(\S*\d+)\s+PH_K2i=\s*(\S*\d+)\s+PH_K0e=\s*(\S*\d+)\s+PH_K2e=\s*(\S*\d+)/
        )
    {
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PH_K0i"} = $1;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PH_K2i"} = $2;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PH_K0e"} = $3;
      $sensor_coefficients{$sensor_model}->{$sensor_SN}->[ $sample_index ]
          ->{"PH_K2e"} = $4;
      $sample_index++;
    }

  }
  close( SENSOR_CAL_DATA );

  #print "sensor coefficients, parser =".Dumper(\%sensor_coefficients)."\n";

  return %sensor_coefficients;

}

# END parse_sensorCoeff subroutine

#*************************************************************#
#* parse_deployHist : Parse the file containing sensor       *#
#* deployment history                                        *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: sensor deployment history                *#
#*************************************************************#
sub parse_deployHist
{

  my $sensor_deployment_hist_file = shift;

  #
  # Open sensor deployment file
  open SENS_DPLY_HSTRY, "<$sensor_deployment_hist_file"
      || die "error! could not open calibration data file!\n";
  #
  # TODO: parse serial2 (aquadopp or ecolab)
  #
  # sensor deployment history file format:
  # [01/01/05 12:00]
  # CAST=ORCA2_CAST0001.HEX
  # CTD=SBE19 SN=2835
  # PUMP=5T SN=052902
  # V0=O2 Model=SBE43 SN=0015
  # V1=Fluor Model=WetStar SN=WS3S-586P
  # V2=NA Model=NA SN=NA
  # V3=NA Model=NA SN=NA
  # V4=NA Model=NA SN=NA
  # V5=NA Model=NA SN=NA
  # CTDSerial=pH Model=SEAFET SN=217
  # Serial2=Currents Model=Aquadopp SN=2348
  #
  # Define variables
  my $found_first_sensor_record = 0;
  my $history_index             = 0;
  my @sensor_deployment         = ();

## RMH: Make subroutine.  Add validation code.
  # Read data line by line
  while ( <SENS_DPLY_HSTRY> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    # Extract time
    if ( /^\s*\[\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)\s*\]/ )
    {

      # Set incrementation
      if ( $found_first_sensor_record == 1 )
      {
        $history_index++;
      }
      $found_first_sensor_record = 1;

      # Extract and store time
      my $time = timelocal( 0, $5, $4, $2, $1 - 1, $3 );
      $sensor_deployment[ $history_index ]->{"time"} = $time;

      #print $history_index;
    }

    # Identify CAST
    if ( /\s*CAST\s*=\s*(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"CAST"} = $1;
    }

    # Identify CTD and SN
    if ( /\s*CTD\s*=\s*(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"CTD"}    = $1;
      $sensor_deployment[ $history_index ]->{"CTD_SN"} = $2;
    }

    # Identify Pump type and SN
    if ( /\s*PUMP\s*=\s*(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"PUMP"}    = $1;
      $sensor_deployment[ $history_index ]->{"PUMP_SN"} = $2;
    }

    # Identify V0 and SN
    if ( /\s*V0\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"V0_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"V0_model"} = $2;
      $sensor_deployment[ $history_index ]->{"V0_SN"}    = $3;
    }

    # Identify V1 and SN
    if ( /\s*V1\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"V1_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"V1_model"} = $2;
      $sensor_deployment[ $history_index ]->{"V1_SN"}    = $3;
    }

    # Identify V2 and SN
    if ( /\s*V2\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"V2_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"V2_model"} = $2;
      $sensor_deployment[ $history_index ]->{"V2_SN"}    = $3;
    }

    # Identify V3 and SN
    if ( /\s*V3\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"V3_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"V3_model"} = $2;
      $sensor_deployment[ $history_index ]->{"V3_SN"}    = $3;
    }

    # Identify V4 and SN
    if ( /\s*V4\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"V4_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"V4_model"} = $2;
      $sensor_deployment[ $history_index ]->{"V4_SN"}    = $3;
    }

    # Identify V5 and SN
    if ( /\s*V5\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"V5_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"V5_model"} = $2;
      $sensor_deployment[ $history_index ]->{"V5_SN"}    = $3;
    }

    # Identify CTDSerial and SN
    if ( /\s*CTDSerial\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"CTDSerial_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"CTDSerial_model"} = $2;
      $sensor_deployment[ $history_index ]->{"CTDSerial_SN"}    = $3;
    }

    # Identify Serial2
    if ( /\s*Serial2\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $sensor_deployment[ $history_index ]->{"Serial2_type"}  = $1;
      $sensor_deployment[ $history_index ]->{"Serial2_model"} = $2;
      $sensor_deployment[ $history_index ]->{"Serial2_SN"}    = $3;
    }

  }
  close( SENS_DPLY_HSTRY );

  #print "sensor deployment history, parser =".Dumper(\@sensor_deployment)."\n";

  return @sensor_deployment;

}

# END parse_deployHist subroutine

#*************************************************************#
#* parse_AuxDeployHist : Parse the file containing auxiliary *#
#* sensor deployment history                                 *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: auxiliary sensor deployment history      *#
#*************************************************************#
sub parse_AuxDeployHist
{

  my $aux_sensor_deployment_hist_file = shift;

  #
  # Open sensor deployment file
  open SENS_DPLY_HSTRY, "<$aux_sensor_deployment_hist_file"
      || die "error! could not open calibration data file!\n";

  # aux sensor deployment history file format:

  # [01/01/2015 12:00]
  # Weather=GILL Model=METPAK SN=467
  # Wind=RMYOUNG Model=X SN=4
  # Compass=RMYOUNG Model=X SN=5
  # Par=LICOR Model=LI190 SN=47559
  # pH=SATLANTIC Model=SEAFET SN=257
  # Computer=ADS Model=BITSYX SN=0015
  #
  #
  # Define variables
  my $found_first_sensor_record = 0;
  my $history_index             = 0;
  my @aux_sensor_deployment     = ();

  # Read data line by line
  while ( <SENS_DPLY_HSTRY> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    # Extract time
    if ( /^\s*\[\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+)\s*\]/ )
    {

      # Set incrementation
      if ( $found_first_sensor_record == 1 )
      {
        $history_index++;
      }
      $found_first_sensor_record = 1;

      # Extract and store time
      my $time = timelocal( 0, $5, $4, $2, $1 - 1, $3 );
      $aux_sensor_deployment[ $history_index ]->{"time"} = $time;

      #print $history_index;
    }

    # Identify Weather and SN
    if ( /\s*Weather\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"Weather_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"Weather_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"Weather_SN"}    = $3;
    }

    # Identify Wind and SN
    if ( /\s*Wind\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"Wind_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"Wind_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"Wind_SN"}    = $3;
    }

    # Identify Compass and SN
    if ( /\s*Compass\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"Compass_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"Compass_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"Compass_SN"}    = $3;
    }

    # Identify PAR and SN
    if ( /\s*Par\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"PAR_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"PAR_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"PAR_SN"}    = $3;
    }

    # Identify pH and SN
    if ( /\s*pH\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"PH_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"PH_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"PH_SN"}    = $3;
    }

    # Identify Computer and SN
    if ( /\s*Computer\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"Computer_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"Computer_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"Computer_SN"}    = $3;
    }

    # Identify Router and SN
    if ( /\s*Router\s*=\s*(\S+)\s+Model=(\S+)\s+SN=(\S+)/ )
    {
      $aux_sensor_deployment[ $history_index ]->{"Router_type"}  = $1;
      $aux_sensor_deployment[ $history_index ]->{"Router_model"} = $2;
      $aux_sensor_deployment[ $history_index ]->{"Router_SN"}    = $3;
    }

  }
  close( SENS_DPLY_HSTRY );

#print "aux sensor deployment history, parser =".Dumper(\@aux_sensor_deployment)."\n";

  return @aux_sensor_deployment;

}

# END parse_AuxDeployHist subroutine

#*************************************************************#
#* parse_DGC : Parse DGC file containing all the CTD data    *#
#*                                                           *#
#* Input to function: file name                              *#
#* Returns to main: CTD data                                 *#
#*************************************************************#
sub parse_DGC
{

  my $DGC_file = shift;

  #print "DGC file is: $DGC_file\n";
  #
  # Open DGC data file
  #
  open DGC_DATA_FILE,
      "<$DGC_file" || die "error! could not open DGC data file!\n";

  # DGC file format
  # CTD header information, followed by data in the following columns:
  # column 1: Scan Number
  # column 2: Pressure, db
  # column 3: Conductivity, S/m
  # column 4: Temperature, degrees C
  # column 5: Voltage channel 0, volts
  # column 6: Voltage channel 1, volts
  # column 7: Voltage channel 2, volts
  # column 8: Voltage channel 3, volts
  # column 9: Voltage channel 4, volts
  # column 10: Votlage channel 5, volts
  # column 11: Oxygen voltage, volts
  # column 12: Fluorometer, mg/m^3
  # column 13: NO3, umol
  # column 14: Depth, m
  # column 15: Salinity, psu
  # column 16: Sigma-T, kg/m^3
  # column 17: Oxygen, mg/L
  # column 18: Oxygen, umol/kg
  # column 19: Oxygen saturation, mg/L
  # column 20: PAR, uEinsteins/m^2-sec
  # column 21: Turbidity, NTU

  # Define variables
  my @DGC_data  = ();
  my $dgc_index = 0;
  my $sample_rate;
  my $hex_time;

  # Read data line by line
  while ( <DGC_DATA_FILE> )
  {
    next if ( /^\s*\#.*/ );
    next if ( /^\s*$/ );

    #
    # Read in CTD time
    #

    if (
/^.*SEACAT PROFILER\s+\S+\s+\S+\s+\S+\s+(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)\.\d+.*/
      || /^.*SeacatPlus\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+).*/
        )
    {

      #print $_;
      my $variable_1 = $1;
      my $variable_2 = $2;
      my $year       = $3;
      my $hour       = $4;
      my $minute     = $5;
      my $second     = $6;
      my $month      = 0;
      my $day        = 0;
      if ( $variable_2 !~ m/\d/ )
      {
        $day = $variable_1;
        if ( $2 eq "Jan" ) { $month = 1 }
        if ( $2 eq "Feb" ) { $month = 2 }
        if ( $2 eq "Mar" ) { $month = 3 }
        if ( $2 eq "Apr" ) { $month = 4 }
        if ( $2 eq "May" ) { $month = 5 }
        if ( $2 eq "Jun" ) { $month = 6 }
        if ( $2 eq "Jul" ) { $month = 7 }
        if ( $2 eq "Aug" ) { $month = 8 }
        if ( $2 eq "Sep" ) { $month = 9 }
        if ( $2 eq "Oct" ) { $month = 10 }
        if ( $2 eq "Nov" ) { $month = 11 }
        if ( $2 eq "Dec" ) { $month = 12 }
      } else
      {
        $day   = $variable_2;
        $month = $variable_1;
      }
      $hex_time = timelocal( $second, $minute, $hour, $day, $month - 1, $year );

      #print "$hex_time\n";
    }

    #
    #
    # Read in sample frequency
    #
    #
    if ( /.*avg\s*=\s*(\d+).*/ )
    {
      $sample_rate = 1 / ( $1 * 0.25 );

      #print "Sample rate = $sample_rate\n";
    }

    # 19 format "* sample rate = 1 scan every 0.5 seconds"
    #
    if ( /^\s*.?\s*sample\s+rate\s*=\s*(\d+)\s+scan\s+every\s+(\S*\d+)\S*/ )
    {
      $sample_rate = $1 / $2;

      #print "Sample rate = $sample_rate\n";
    }

    # Extract data
    if ( /^\s*[\d\.]+\s+[\d\.]+\s+/ )
    {
      #print "found a record!!!!!\n";
      my @cols = split;

      #print $cols[0] ."\t";
      #print $cols[1] ."\t";
      #print $cols[2] ."\t";
      #print $cols[3] ."\t";
      #print $cols[4] ."\t";
      #print $cols[5] ."\t";
      #print $cols[6] ."\t";
      #print $cols[7] ."\t";
      #print $cols[8] ."\t";
      #print $cols[9] ."\t";
      #print $cols[10] ."\t";
      #print $cols[11] ."\t";
      #print $cols[12] ."\t";
      #print $cols[13] ."\t";
      #print $cols[14] ."\t";
      #print $cols[15] ."\t";
      #print $cols[16] ."\t";
      #print $cols[17] ."\t";
      #print $cols[18] ."\t";
      #print $cols[19] ."\t";
      #print $cols[20] ."\n";

      $DGC_data[ $dgc_index ]->{"scan"}        = $cols[ 0 ];
      $DGC_data[ $dgc_index ]->{"Press_db"}    = $cols[ 1 ];
      $DGC_data[ $dgc_index ]->{"Cond"}        = $cols[ 2 ];
      $DGC_data[ $dgc_index ]->{"Temp"}        = $cols[ 3 ];
      $DGC_data[ $dgc_index ]->{"V0_raw"}      = $cols[ 4 ];
      $DGC_data[ $dgc_index ]->{"V1_raw"}      = $cols[ 5 ];
      $DGC_data[ $dgc_index ]->{"V2_raw"}      = $cols[ 6 ];
      $DGC_data[ $dgc_index ]->{"V3_raw"}      = $cols[ 7 ];
      $DGC_data[ $dgc_index ]->{"V4_raw"}      = $cols[ 8 ];
      $DGC_data[ $dgc_index ]->{"V5_raw"}      = $cols[ 9 ];
      $DGC_data[ $dgc_index ]->{"O2_volts"}    = $cols[ 10 ];
      $DGC_data[ $dgc_index ]->{"Fluor"}       = $cols[ 11 ];
      $DGC_data[ $dgc_index ]->{"NO3"}         = $cols[ 12 ];
      $DGC_data[ $dgc_index ]->{"Depth_m"}     = $cols[ 13 ];
      $DGC_data[ $dgc_index ]->{"Salinity"}    = $cols[ 14 ];
      $DGC_data[ $dgc_index ]->{"SigmaT"}      = $cols[ 15 ];
      $DGC_data[ $dgc_index ]->{"Oxy_mgL"}     = $cols[ 16 ];
      $DGC_data[ $dgc_index ]->{"Oxy_umol"}    = $cols[ 17 ];
      $DGC_data[ $dgc_index ]->{"Oxy_sat_mgL"} = $cols[ 18 ];
      $DGC_data[ $dgc_index ]->{"PAR"}         = $cols[ 19 ];
      $DGC_data[ $dgc_index ]->{"Turb"}        = $cols[ 20 ];

      $dgc_index++;
    }
  }
  close( DGC_DATA_FILE );

  #print "DGC data =".Dumper(\@DGC_data)."\n";

  return ( $hex_time, $sample_rate, @DGC_data );
}

# END parse_DGC subroutine

#*************************************************************#
#* parse_surface365 : Parse txt file containing CTD data for *#
#* the top bin for temp, sal, sigma, oxygen for the          *#
#* previous 365 days (created by MatLAB).                    *#
#* Input to function: file name                              *#
#* Returns to main: CTD data                                 *#
#*************************************************************#
sub parse_surface365
{

  my $surface_file    = shift;
  my @surface365_data = ();
  my $data_index      = 0;
  #
  # Open data file
  #
  open SURFACE_DATA_FILE,
      "<$surface_file" || die "error! could not open surface data file!\n";

  while ( <SURFACE_DATA_FILE> )
  {
    chomp;
    my @cols = split( /\t/ );
    $surface365_data[ $data_index ]->{"yearday"}  = $cols[ 0 ];
    $surface365_data[ $data_index ]->{"temp"}     = $cols[ 1 ];
    $surface365_data[ $data_index ]->{"sal"}      = $cols[ 2 ];
    $surface365_data[ $data_index ]->{"sigma"}    = $cols[ 3 ];
    $surface365_data[ $data_index ]->{"oxy_umol"} = $cols[ 4 ];
    $surface365_data[ $data_index ]->{"oxy_mgL"}  = $cols[ 5 ];
    $data_index++;
  }
  close SURFACE_DATA_FILE;

  #print "surface data =".Dumper(\@surface365_data)."\n";

  return @surface365_data;

}

# END parse_surface365 subroutine

### END subroutines

1;
