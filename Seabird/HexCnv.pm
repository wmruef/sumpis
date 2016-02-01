#!/usr/bin/perl

package Seabird::HexCnv;

use strict;
use Time::Local;
use Data::Dumper;
use stats;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA         = qw(Exporter);
@EXPORT      = qw(hexfile2cnv_data Oxysat volts2pH);
@EXPORT_OK   = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* auxVolt_calc: Calculate the engineering units for         *#
#* auxillary voltages                                        *#
#* Input to function: raw decimal, sensor type,              *#
#* sensor calibration coefficients, salinity, temp, press,   *#
#* temperature convention (T68 or T90)                       *#
#* Returns to main: engineering units                        *#
#*************************************************************#
sub auxVolt_calc
{
  my $data_raw   = shift;
  my $data_type  = shift;
  my $data_coeff = shift;
  my $sal        = shift;
  my $temp       = shift;
  my $press      = shift;
  my $temp_conv  = shift;

  my $DEBUG = 0;

  # TODO make more flexible
  die "HexConv::auxVolt_calc(): For now this routine expects T68\n"
      if ( $temp_conv ne "T68" );

  if ( $DEBUG )
  {
    print "auxVolt_Calc(): Entered\n";
    print "  Data Type: $data_type\n";
    print "  Data Raw : $data_raw\n";
  }

  if ( $data_type eq "O2" )
  {

# Calculate oxygen value
#
# Equation 1: (SBE 43 SN: 0070)
#   oxygen (ml/l) = (Soc * v + Boc * exp(-0.03*t)) * exp(Tcor*t) * Oxsat(t,s)
#
# Equation 2: (All other SBE-43s, pre-June 2008)
#   oxygen (ml/l) = (Soc * (V + Voffset)) * exp(Tcor*t) * Oxsat(t,s) * exp(Pcor*p)
#
#   where Oxsat(t,s) = Oxygen saturation value after Wiess (1970)
#
#     Weiss, R. F., 1970: The solubility of nitrogen, oxygen and argon
#     in water and seawater. Deep-Sea Res., 17, 721-735.
#
# Equation 3: All SBE-43s after June 2008
#   oxygen (ml/l) = Soc * (V + Voffset + (tau20*D0*exp(D1*p+D2*t))) *
#                   (1.0 + A*t + B*t^2 + C*t^3)
#                   * Oxysol(t,s) * exp(E * p/K)
#
#   where t = temp, deg C;
#       s = sal, psu;
#       p = pressure, dbar;
#       K = temp, deg K
#       Soc = Oxygen slope
#       V = Sensor output in volts
#       Voffset = Sensor offset voltage
#       Oxysol = Oxygen solubility after Garcia and Gorden ( 1992 )
#       tau20 = Sensor time constant at 20 deg C and 1 Atm
#       D0,D1,D2 = Compensation coeff for pressure effect on time constant
#       dV/dt  = Estimate of sensor output change over time.
#       E = Compensation coeff for pressure effect on membrane permeability
#
#   see http://www.seabird.com/technical_references/NewDOEqtnPosterMarch08-4Pages.pdf
#
#

    # Sanity check
    if (    $data_raw < 0
         || $data_type eq ""
         || $data_coeff eq ""
         || $sal < 0
         || $temp < 0
         || $press < 0
         || $temp_conv !~ /^T68|T90$/ )
    {
      warn "O2 parameters to auxVolt_calc() are strange!\n";
      $DEBUG = 1;
    }

## TODO make sure temp is in T68

    my $Oxysat_test_printout = Oxysat( $sal, $temp, $temp_conv, "ml/l" );
    my $Oxysol_test_printout = Oxysol( $sal, $temp, $temp_conv, "ml/l" );

    # Debug
    if ( $DEBUG )
    {
      print "  02 Calculation:\n";
      print "    Sal: $sal\n    Temp: $temp\n    Temp_conv: $temp_conv\n";
      print "    Press: $press\n    Volts: $data_raw\n";
      print "    Oxysat: $Oxysat_test_printout\n";
      print "    Oxysol: $Oxysol_test_printout\n";
      print "    eqn: " . $data_coeff->{"eqn"} . "\n";
      print "    O2_Soc: " . $data_coeff->{"O2_Soc"} . "\n";
      print "    O2_Voffset: " . $data_coeff->{"O2_Voffset"} . "\n";
      print "    O2_tau20: " . $data_coeff->{"O2_tau20"} . "\n";
      print "    O2_A: " . $data_coeff->{"O2_A"} . "\n";
      print "    O2_B: " . $data_coeff->{"O2_B"} . "\n";
      print "    O2_C: " . $data_coeff->{"O2_C"} . "\n";
      print "    O2_E: " . $data_coeff->{"O2_E"} . "\n";
    }

    my $O2_ml;
    if ( $data_coeff->{"eqn"} == 2 )
    {
      $O2_ml =
          (
         $data_coeff->{"O2_Soc"} * ( $data_raw + $data_coeff->{"O2_Voffset"} ) )
          * exp( $data_coeff->{"O2_TCor"} * $temp )
          * Oxysat( $sal, $temp, $temp_conv, "ml/l", "T68" )
          * exp( $data_coeff->{"O2_PCor"} * $press );

    } elsif ( $data_coeff->{"eqn"} == 3 )
    {
      # This formula is designed for T90 temps whereas the Oxysol()
      # routine is flexible ( you can pass it either as long as you
      # specify it ).
      #
      #  If we are fed the Seabird standard of ITPS-68 we need to
      #  convert first.
      #  Seabird formulas
      #   T68 = 1.00024*T90
      #   T90 = T68/1.00024
      my $t90_temp = $temp;
      if ( $temp_conv ne "T90" )
      {
        if ( $temp_conv eq "T68" )
        {
          $t90_temp = $temp / 1.00024;    # in ITPS-90 now
        } else
        {
          die "HexConv.pm::auxVolt_calc(): Called using a unknown "
              . "temperature convention \"$temp_conv\"\n";
        }
      }

      # Seabird rounds off O2 voltage at 4 decimal places.
      # TODO: consider turning this on/off with a cmd line switch
      $data_raw = sprintf( "%.4f", $data_raw );
      $O2_ml = (
        $data_coeff->{"O2_Soc"} *
            ( $data_raw + $data_coeff->{"O2_Voffset"} ) *
            (
              1.0 + ( $data_coeff->{"O2_A"} * $t90_temp ) +
                  ( $data_coeff->{"O2_B"} * $t90_temp**2 ) +
                  ( $data_coeff->{"O2_C"} * $t90_temp**3 )
            ) *
            Oxysol( $sal, $t90_temp, "T90", "ml/l" ) *
            exp( ( $data_coeff->{"O2_E"} * $press ) / ( $t90_temp + 273.15 ) )

      );

    }

    if ( $DEBUG )
    {
      print "    Results: O2_ml   = $O2_ml\n";
    }

    return $O2_ml;
  } elsif ( $data_type eq "Fluor" )
  {

    # Calculate chlorophyll values
    # Equation 1 (Wetstar fluorometers)
    #   Clor_mgL = Chlor_scale_factor * ( raw - Chlor_offset )
    my $Chlor_mgL =
        $data_coeff->{"Chlor_scale_factor"} *
        ( $data_raw - $data_coeff->{"Chlor_offset"} );

    # return $chlorophyll and $Fluor_volts
    return $Chlor_mgL;
  } elsif ( $data_type eq "NA" )
  {

    # return "NAN" and raw voltage
    # return back raw voltage
    return $data_raw;
  } elsif ( $data_type eq "Turb" )
  {

    # calculate turbidity values
    #print "turbidity coeffs".Dumper ($data_coeff)."\n";
    #print "turbidity voltag...$data_raw\n";
    # Equation 1 (WetLabs ECO-FLNTUS)
    my $Turb_NTU =
        $data_coeff->{"Turb_scale_factor"} *
        ( $data_raw - $data_coeff->{"Turb_offset"} );

    # return $turbidity and $Turb_volts
    return $Turb_NTU;
  } elsif ( $data_type eq "NO3" )
  {

    # calculate NO3 values
    #print Dumper ($data_coeff);
    my $NO3_umol =
        ( $data_coeff->{"NO3_A1"} * $data_raw ) + $data_coeff->{"NO3_A0"};

    return $NO3_umol;
  } elsif ( $data_type eq "PAR" )
  {

    # calculate PAR values
    #print Dumper ($data_coeff);
    my $PAR;
    if (    ( $data_coeff->{"PAR_m"} == 1 )
         && ( $data_coeff->{"PAR_b"} == 0 ) )
    {
      $PAR =
          ( ( 10**9 * 10**$data_raw ) / $data_coeff->{"PAR_cal_constant"} ) +
          $data_coeff->{"PAR_offset"};
    } else
    {
      $PAR = (
               10**6 * 10**(
                 ( $data_raw - $data_coeff->{"PAR_b"} ) / $data_coeff->{"PAR_m"}
               )
          ) /
          $data_coeff->{"PAR_cal_constant"} * 1000 *
          $data_coeff->{"PAR_multiplier"};
    }

    return $PAR;
  } elsif ( $data_type eq "Trans" )
  {

    # calculate Trans values
    #print Dumper ($data_coeff);
    my $Trans =
        $data_coeff->{"Trans_m"} * ( $data_raw - $data_coeff->{"Trans_b"} );
    return $Trans;
  } else
  {
    print "Unknown data type $data_type!\n";
  }
}

# END auxVolt_calc subroutine

#*************************************************************#
#* calcDepth: converts pressure (db) to depth (m)            *#
#* Input to function: pressure, latitude                     *#
#* Returns to main: depth                                    *#
#*************************************************************#
sub calcDepth
{
  my $press    = shift;
  my $latitude = shift;

  my $depth = 0;
  my $x     = ( sin( $latitude / 57.29578 ) )**2;
  my $gr =
      9.780318 * ( 1.0 + ( 5.2788e-03 + 2.36e-05 * $x ) * $x ) +
      1.092e-06 * $press;
  my $d =
      ( ( ( -1.82e-15 * $press + 2.279e-10 ) * $press - 2.2512e-05 ) * $press +
        9.72659 ) *
      $press;
  if ( $gr > 0 )
  {
    $depth = $d / $gr;
  }

  return $depth

}

# END calcDepth

#*************************************************************#
#* calcSigma: Calculates sigma via equation of state         *#
#* Input to function: salinity (psu),temp (C),pressure (db)  *#
#* temp convention (ITPS-68 = T68, ITPS-90 = T90)            *#
#* Returns to main: sigma (kg/m^3)                           *#
#*************************************************************#
sub calcSigma
{
  my $salinity  = shift;
  my $temp      = shift;
  my $press     = shift;
  my $temp_conv = shift;

  # The following equations need temperature to be
  # in ITPS-68.  If we are fed the Seabird standard
  # of ITPS-90 we need to convert first.
  # Seabird formulas
  #   T68 = 1.00024*T90
  #   T90 = T68/1.00024
  if ( $temp_conv ne "T68" )
  {
    if ( $temp_conv eq "T90" )
    {
      $temp = $temp * 1.00024;
    } else
    {
      die "HexConv.pm::calcSigma(): Called using a unknown "
          . "temperature convention \"$temp_conv\"\n";
    }
  }

  # Convert pressure into bars
  $press /= 10;

# Compute density (kg/m3) at the surface from salinity (psu) and temperature (degC)
  my $A = 1.001685e-04 + $temp * ( -1.120083e-06 + $temp * 6.536332e-09 );
  my $A2 = 999.842594 +
      $temp * ( 6.793952e-02 + $temp * ( -9.095290e-03 + $temp * $A ) );
  my $B  = 7.6438e-05 + $temp *   ( -8.2467e-07 + $temp * 5.3875e-09 );
  my $B2 = 0.824493 + $temp *     ( -4.0899e-03 + $temp * $B );
  my $C  = -5.72466e-03 + $temp * ( 1.0227e-04 - $temp * 1.6546e-06 );
  my $D  = 4.8314e-04;
  my $d0 = $A2 + $salinity * ( $B2 + $C * $salinity**( 0.5 ) + $D * $salinity );

# Compute density (kg/m3) from salinity (psu), temperature (degC) and pressure (dbar)

  my $temp2 = $temp * $temp;
  my $temp3 = $temp2 * $temp;
  my $temp4 = $temp3 * $temp;

  my $E =
      19652.21 + 148.4206 * $temp -
      2.327105 * $temp2 +
      1.360477e-2 * $temp3 -
      5.155288e-5 * $temp4;
  my $F = 54.6746 - 0.603459 * $temp + 1.09987e-2 * $temp2 - 6.1670e-5 * $temp3;
  my $G = 7.944e-2 + 1.6483e-2 * $temp - 5.3009e-4 * $temp2;
  my $H =
      3.239908 + 1.43713e-3 * $temp + 1.16092e-4 * $temp2 - 5.77905e-7 * $temp3;
  my $I    = 2.2838e-3 - 1.0981e-5 * $temp - 1.6078e-6 * $temp2;
  my $J    = 1.91075e-4;
  my $M    = 8.50935e-5 - 6.12293e-6 * $temp + 5.2787e-8 * $temp2;
  my $N    = -9.9348e-7 + 2.0816e-8 * $temp + 9.1697e-10 * $temp2;
  my $s1p5 = $salinity**( 1.5 );
  my $K =
      ( $E + $F * $salinity + $G * $s1p5 ) +
      ( $H + $I * $salinity + $J * $s1p5 ) * $press +
      ( $M + $N * $salinity ) * $press**2;
  my $sigma = ( $d0 / ( 1 - $press / $K ) ) - 1000;

  return $sigma;
}

# END calcSigma subroutine

#*************************************************************#
#* Density: Calculate the density based on the equation of   *#
#*          state (EOS80).                                   *#
#* Input to function: salinity (psu),temp (T68 C),           *#
#* pressure (db)                                             *#
#* Returns to main: sigma (kg/m^3)                           *#
#*************************************************************#
sub Density
{
  my $sal       = shift;
  my $temp      = shift;
  my $temp_conv = shift;
  my $press     = shift;

  my $B0 = 8.24493e-1;
  my $B1 = -4.0899e-3;
  my $B2 = 7.6438e-5;
  my $B3 = -8.2467e-7;
  my $B4 = 5.3875e-9;
  my $C0 = -5.72466e-3;
  my $C1 = 1.0227e-4;
  my $C2 = -1.6546e-6;
  my $D0 = 4.8314e-4;
  my $A0 = 999.842594;

  my $A1 = 6.793952e-2;
  my $A2 = -9.095290e-3;
  my $A3 = 1.001685e-4;
  my $A4 = -1.120083e-6;
  my $A5 = 6.536332e-9;

  my $FQ0 = 54.6746;
  my $FQ1 = -0.603459;
  my $FQ2 = 1.09987e-2;
  my $FQ3 = -6.1670e-5;
  my $G0  = 7.944e-2;
  my $G1  = 1.6483e-2;
  my $G2  = -5.3009e-4;
  my $i0  = 2.2838e-3;
  my $i1  = -1.0981e-5;
  my $i2  = -1.6078e-6;
  my $J0  = 1.91075e-4;
  my $M0  = -9.9348e-7;
  my $M1  = 2.0816e-8;
  my $M2  = 9.1697e-10;
  my $E0  = 19652.21;
  my $E1  = 148.4206;
  my $E2  = -2.327105;
  my $E3  = 1.360477e-2;

  my $E4 = -5.155288e-5;
  my $H0 = 3.239908;
  my $H1 = 1.43713e-3;
  my $H2 = 1.16092e-4;
  my $H3 = -5.77905e-7;

  my $K0 = 8.50935e-5;
  my $K1 = -6.12293e-6;
  my $K2 = 5.2787e-8;

  my $t2 = $temp**2;
  my $t3 = $temp**3;
  my $t4 = $temp**4;
  my $t5 = $temp**5;

  $sal = 0.000001 if ( $sal <= 0.0 );
  my $s32 = $sal**1.5;
  $press /= 10.0;
  my $sigma =
      $A0 +
      $A1 * $temp +
      $A2 * $t2 +
      $A3 * $t3 +
      $A4 * $t4 +
      $A5 * $t5 +
      ( $B0 + $B1 * $temp + $B2 * $t2 + $B3 * $t3 + $B4 * $t4 ) * $sal +
      ( $C0 + $C1 * $temp + $C2 * $t2 ) * $s32 +
      $D0 * $sal * $sal;

  my $kw = $E0 + $E1 * $temp + $E2 * $t2 + $E3 * $t3 + $E4 * $t4;
  my $aw = $H0 + $H1 * $temp + $H2 * $t2 + $H3 * $t3;
  my $bw = $K0 + $K1 * $temp + $K2 * $t2;
  my $k =
      $kw +
      ( $FQ0 + $FQ1 * $temp + $FQ2 * $t2 + $FQ3 * $t3 ) *
      $sal +
      ( $G0 + $G1 * $temp + $G2 * $t2 ) *
      $s32 +
      ( $aw + ( $i0 + $i1 * $temp + $i2 * $t2 ) * $sal + ( $J0 * $s32 ) ) *
      $press +
      ( $bw + ( $M0 + $M1 * $temp + $M2 * $t2 ) * $sal ) *
      $press * $press;
  my $val = 1 - $press / $k;
  $sigma = $sigma / $val - 1000.0 if ( $val );

  return $sigma;
}

## TODO Deprecated
#*************************************************************#
#* calcSigma_seabird: Calculates sigma via equation of state  #
#* Input to function: salinity (psu),temp (C),pressure (db)  *#
#* Returns to main: sigma (kg/m^3)                           *#
#*************************************************************#
sub calcSigma_seabird
{
  my $salinity = shift;
  my $temp     = shift;
  my $press    = shift;

  # Define constants
  my @A = (
            999.842594,    6.793952e-02, -9.095290e-03, 1.001685e-04,
            -1.120083e-06, 6.536332e-09
  );
  my @B = ( 8.24493e-01, -4.0899e-03, 7.6438e-05, -8.2467e-07, 5.3875e-09 );
  my @C = ( -5.72466e-03, 1.0227e-04, -1.6546e-06 );
  my $D0 = 4.8314e-04;
  my @FQ = ( 54.6746, -0.603459, 1.09987e-02, -6.1670e-05 );
  my @G  = ( 7.944e-02, 1.6483e-02, -5.3009e-04 );
  my @i  = ( 2.2838e-03, -1.0981e-05, -1.6078e-06 );
  my $J0 = 1.91075e-04;
  my @M  = ( -9.9348e-07, 2.0816e-08, 9.1697e-10 );
  my @E  = ( 19652.21, 148.4206, -2.327105, 1.360477e-02, -5.155288e-05 );
  my @H  = ( 3.239908, 1.43713e-03, 1.16092e-04, -5.77905e-07 );
  my @K  = ( 8.50935e-05, -6.12293e-06, 5.2787e-08 );

  # Convert T90 Temp into T68
  $temp *= 1.00024;

  # Convert db into bars
  $press /= 10;
  my $equation1 =
      $A[ 0 ] +
      $A[ 1 ] * $temp +
      $A[ 2 ] *
      ( $temp**2 ) +
      $A[ 3 ] *
      ( $temp**3 ) +
      $A[ 4 ] *
      ( $temp**4 ) +
      $A[ 5 ] *
      ( $temp**5 ) +
      ( $B[ 0 ] +
        $B[ 1 ] * $temp +
        $B[ 2 ] * ( $temp**2 ) +
        $B[ 3 ] * ( $temp**3 ) +
        $B[ 4 ] * ( $temp**4 ) ) *
      $salinity +
      ( $C[ 0 ] + $C[ 1 ] * $temp + $C[ 2 ] * ( $temp**2 ) ) *
      ( $salinity**1.5 ) +
      $D0 *
      ( $salinity**2 );

  my $kw =
      $E[ 0 ] +
      $E[ 1 ] * $temp +
      $E[ 2 ] * ( $temp**2 ) +
      $E[ 3 ] * ( $temp**3 ) +
      $E[ 4 ] * ( $temp**4 );
  my $aw =
      $H[ 0 ] +
      $H[ 1 ] * $temp +
      $H[ 2 ] * ( $temp**2 ) +
      $H[ 3 ] * ( $temp**3 );
  my $bw = $K[ 0 ] + $K[ 1 ] * $temp + $K[ 2 ] * ( $temp**2 );
  my $k =
      $kw +
      ( $FQ[ 0 ] +
        $FQ[ 1 ] * $temp +
        $FQ[ 2 ] * ( $temp**2 ) +
        $FQ[ 3 ] * ( $temp**3 ) ) *
      $salinity +
      ( $G[ 0 ] + $G[ 1 ] * $temp + $G[ 2 ] * ( $temp**2 ) ) *
      ( $salinity**1.5 ) +
      ( $aw +
        ( $i[ 0 ] + $i[ 1 ] * $temp + $i[ 2 ] * ( $temp**2 ) ) * $salinity +
        ( $J0 * ( $salinity**1.5 ) ) ) *
      $press +
      (
      $bw + ( $M[ 0 ] + $M[ 1 ] * $temp + $M[ 2 ] * ( $temp**2 ) ) * $salinity )
      * ( $press**2 );

  my $value = 1 - $press / $k;
  my $sigma = $equation1 / $value - 1000.00;

 #my $equation2 = $E[ 0 ] + $E[ 1 ] * $temp + $E[ 2 ] * ( $temp**2 ) + $E[ 3 ] *
 #    ( $temp**3 ) + $E[ 4 ] * ( $temp**4 ) +
 #    ( $FQ[ 0 ] + $FQ[ 1 ] * $temp + $FQ[ 2 ] * ( $temp**2 ) + $FQ[ 3 ] *
 #      ( $temp**3 ) ) * $salinity +
 #    ( $G[ 0 ] + $G[ 1 ] * $temp + $G[ 2 ] * ( $temp**2 ) ) *
 #    ( $salinity**1.5 ) + (
 #   $H[ 0 ] + $H[ 1 ] * $temp + $H[ 2 ] * ( $temp**2 ) + $H[ 3 ] * ( $temp**3 )
 #       + ( $i[ 0 ] + $i[ 1 ] * $temp + $i[ 2 ] * ( $temp**2 ) ) * $salinity +
 #       $J0 * ( $salinity**1.5 ) ) * $press +
 #    ( $K[ 0 ] + $K[ 1 ] * $temp + $K[ 2 ] * ( $temp**2 ) +
 #      ( $M[ 0 ] + $M[ 1 ] * $temp + $M[ 2 ] * ( $temp**2 ) ) * $salinity ) *
 #    ( $press**2 );
 #my $equation3 = 1 - $press / $equation2;
 #my $sigma     = $equation1 / $equation3 - 1000.00;

  return $sigma;
}

# END calcSigma_seabird subroutine

#*************************************************************#
#* cond2sal: convert conductivity into salinity (in psu)     *#
#* Input to function: temp (degrees C), press (db),          *#
#* conductivity (Siemens/meter), temp_conv ( temperature     *#
#* convention - T68 or T90 )                                 *#
#* Returns to main: salinity (psu)                           *#
#*************************************************************#
sub cond2sal
{
  my $temp      = shift;
  my $press     = shift;
  my $cond      = shift;
  my $temp_conv = shift;

 #
 # This routine uses the equations and constants defined in Seabird app note 14;
 #
 # define equation constants
  my @A = ( 2.070e-05,    -6.370e-10,  3.989e-15 );
  my @B = ( 3.426e-02,    4.464e-04,   4.215e-01, -3.107e-03 );
  my @a = ( 0.0080,       -0.1692,     25.3851, 14.0941, -7.0261, 2.7081 );
  my @b = ( 0.0005,       -0.0056,     -0.0066, -0.0375, 0.0636, -0.0144 );
  my @c = ( 6.766097e-01, 2.00564e-02, 1.104259e-04, -6.9698e-07, 1.0031e-09 );
  my $k               = 0.0162;
  my $Cstd            = 42.914;
  my $pressure_offset = 10.1325;

  # Convert conductivity from Siemens/meter to mS/cm
  $cond *= 10;

  # The following equations need temperature to be
  # in ITPS-68.  If we are fed the Seabird standard
  # of ITPS-90 we need to convert first.
  # Seabird formulas
  #   T68 = 1.00024*T90
  #   T90 = T68/1.00024
  if ( $temp_conv ne "T68" )
  {
    if ( $temp_conv eq "T90" )
    {
      $temp = $temp * 1.00024;
    } else
    {
      die "HexConv.pm::cond2sal(): Called using a unknown "
          . "temperature convention \"$temp_conv\"\n";
    }
  }

  # Substract pressure offset
  #my $Pc = $press-$pressure_offset;
  my $Pc = $press;

  # Calculate R
  my $R = $cond / $Cstd;

  # Calculate Rp
  my $Rp = 1 + (
                ( $Pc * ( $A[ 0 ] + $A[ 1 ] * $Pc + $A[ 2 ] * ( $Pc**2 ) ) ) / (
                                                    1 + $B[ 0 ] * $temp +
                                                        $B[ 1 ] * ( $temp**2 ) +
                                                        $B[ 2 ] * $R +
                                                        $B[ 3 ] * $R * $temp
                )
  );

  # Calculate rT
  my $rT =
      $c[ 0 ] +
      $c[ 1 ] * $temp +
      $c[ 2 ] * ( $temp**2 ) +
      $c[ 3 ] * ( $temp**3 ) +
      $c[ 4 ] * ( $temp**4 );

  # Calculate Rt
  my $Rt = $R / ( $Rp * $rT );

  # Calculate Salinity
  my $salinity = 0;
  my $i        = 0;

  my $sal_term1 = 0;
  my $sal_term2 = 0;
  for ( $i = 0 ; $i < 6 ; $i++ )
  {
    $sal_term1 += ( $a[ $i ] * ( $Rt**( $i / 2 ) ) );
    $sal_term2 += ( $b[ $i ] * ( $Rt**( $i / 2 ) ) );
  }
  my $sal_term3 = ( $temp - 15 ) / ( 1 + $k * ( $temp - 15 ) );
  $salinity = $sal_term1 + $sal_term3 * $sal_term2;
  return $salinity;
}

# END cond2sal subroutine

#*************************************************************#
#* hex2dec: Convert hex string to decimal number             *#
#* Input to function: hex string, sign flag                  *#
#* Returns to main: decimal equivalent of hex string         *#
#* Sign flag = 0 does not interpret the first bit as sign    *#
#* Sign flag = 1 interprets first bit as sign                *#
#* with 1 = negative decimal, 0 = positive decimal           *#
#*************************************************************#
sub hex2dec
{
  my $hex_string          = shift;
  my $has_sign_bit        = shift;
  my $hex_length          = length( $hex_string );
  my $hex_char            = 0;
  my $char_position_index = 0;
  my $decimal_number      = 0;
  my $sign_flag           = 0;

  #print "Hex string ==: $hex_string\n";

  for ( my $i = $hex_length - 1 ; $i >= 0 ; $i-- )
  {
    $hex_char = substr( $hex_string, $i, 1 );
    if ( $has_sign_bit > 0 && $i == 0 )
    {
      if ( $hex_char =~ /[A-F89]/ )
      {
        $hex_char =~ tr/89ABCDEF/01234567/;
        $sign_flag = 1;
      }
    } else
    {
      if ( $hex_char =~ /[A-F]/ )
      {
        $hex_char =~ tr/ABCDEF/012345/;
        $hex_char += 10;
      }
    }
    $hex_char *= ( 2**( $char_position_index * 4 ) );
    $char_position_index++;
    $decimal_number += $hex_char;
  }
  if ( $sign_flag == 1 )
  {
    $decimal_number *= -1;
  }

  #print "Decimal equiv: $decimal_number \n";
  return $decimal_number;
}

# END hex2dec subroutine

#*************************************************************#
#* hex2decref: Convert hex string from a reference scan to   *#
#* a decimal number                                          *#
#* Input to function: hex string                             *#
#* Returns to main: decimal equivalent of hex string         *#
#*                  13 bits magnitude                        *#
#*                   1 sign bit                              *#
#*                   2 high bits ignored                     *#
#*************************************************************#
sub hex2decref
{
  my $hex_string = shift;

  my $char_position_index = 0;
  my $decimal_number      = 0;
  my $sign_flag           = 0;

  for ( my $i = length( $hex_string ) - 1 ; $i >= 0 ; $i-- )
  {

    my $hex_char = substr( $hex_string, $i, 1 );
    if ( $char_position_index == 3 )
    {
      if ( $hex_char =~ /[2367ABEF]/ )
      {
        $sign_flag = 1;
      }
      $hex_char =~ tr/23456789ABCDEF/01010101010101/;
    } else
    {
      if ( $hex_char =~ /[A-F]/ )
      {
        $hex_char =~ tr/ABCDEF/012345/;
        $hex_char += 10;
      }
    }
    $hex_char *= ( 2**( $char_position_index * 4 ) );
    $char_position_index++;
    $decimal_number += $hex_char;
  }
  if ( $sign_flag == 1 )
  {
    $decimal_number *= -1;
  }
  return $decimal_number;
}    # END hex2decref subroutine

#*************************************************************#
#* hexfile2cnv_data: Opens hex file and returns all data in  *#
#* engineering units, aligns data if align_flag == 1         *#
#* Input to function: file name, sensor coefficients,        *#
#* sensor deployment history, latitude, alignment flag       *#
#* Returns to main: variables in @cnv_data                   *#
#*************************************************************#
#
# CTD19 Format
#   Contains reference scans
#   Data Lines:
#      if ( /^([A-F0-9]{24,24})\s*$/ ) {
#
#
# CTD19Plus Format
#   No reference scans
#   Data Lines:
#      if ( /^([A-F0-9]{38,38})\s*$/ ) {
#
#
# CTD19Plus V2 Format
#  No reference scans
#  Data Lines:
#     if ( /^([A-F0-9]{46,46})\s*$/ ) {

sub hexfile2cnv_data
{
  my $hex_file_name        = shift;
  my $sensor_coefficients  = shift;
  my $sensor_deployment    = shift;
  my $latitude             = shift;
  my $align_flag           = shift;
  my $useSeabirdTruncation = shift;

  my $DEBUG = 0;
  print "hexfile2cnv_data(): Reading file $hex_file_name\n" if ( $DEBUG );

  my $CTD_coefficients       = 0;
  my $O2_coefficients        = 0;
  my $V0_coefficients        = 0;
  my $V1_coefficients        = 0;
  my $V2_coefficients        = 0;
  my $V3_coefficients        = 0;
  my $V4_coefficients        = 0;
  my $V5_coefficients        = 0;
  my $CTDSerial_coefficients = 0;
  my %coefficients           = ();
  my @cnv_data               = ();
  my $sample_rate;
  my @ref_scans        = ();
  my $has_reference_19 = 0;
  my $hex_data_index   = 0;
  my $ref_scans_index  = -1;
  my $data_scan_index  = 0;
  my $hex_time         = 0;
  my $hex_line         = 0;
  my $CTD_type         = "NA";
  my $V0_type          = "NA";
  my $V1_type          = "NA";
  my $V2_type          = "NA";
  my $V3_type          = "NA";
  my $V4_type          = "NA";
  my $V5_type          = "NA";
  my $CTDSerial_type   = "NA";
  my $SeaFET_present   = "NO";
  my $freq_cor_a       = 0;
  my $freq_cor_b       = 0;
  my $freq_cor_KK      = 2.4018669e-11;
  my $freq_cor_X1      = 9.6036247e-09;
  my $freq_cor_X2      = 1.1949587e-07;
  my $freq_cor_X3 =
      ( $freq_cor_X2 - $freq_cor_X1 ) / ( $freq_cor_X2 * $freq_cor_X1 );
  my $freq_cor_PC = ( 1 / ( 1e06 * $freq_cor_KK ) );
  my $last_deployment_record = 0;

  #print "Opening up $hex_file_name\n";
  # Open file
  open IN, "<$hex_file_name" or die "error! could not open $hex_file_name!\n";
  while ( <IN> )
  {

#
# Extract time from the status section of the .HEX file.
#
# Line format for the CTD19 is:
#    * SEACAT PROFILER V3.1b-22420 SN 2835   04/14/01  04:20:59.291
#    SEACAT PROFILER V3.1b-22420 SN 2835   04/14/01  04:20:59.291
# Line format for the CTD19Plus is:
#    SeacatPlus V 1.5  SERIAL NO. 4679    17 Jan 2006  19:06:13
#
# Line format for the CTD19Plus V2 is:
#    SBE 19plus V 2.0c  SERIAL NO. 6087    01 Apr 2010 10:54:22
#
# The "*" may sometimes precede the header lines.  This was inserted by
# the old buoy control software?
#
# RMH: Note that long regular expressions are hard to read and sometimes very
#      difficult for the computer to efficiently execute.  In these cases you
#      can use a multiple tiered approach to catching the line of interest.
#      First match the minimum sub-pattern size which uniquely identifies the line.
#      Second match the portions of the line you need to extract. In this case:
#
#      my $ctdModel = "Unknown";
#      # Match a CTD19 header
#      if ( /^[\*\s]*SEACAT PROFILER/ )
#      {
#        $ctdModel = "CTD19";
#        if ( /(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)\.\d+.*/ )
#        {
#          ...
#        }else
#        {
#          die  "Seabird::hexfile2cnv_data(): Error! CTD Header is corrupt or "
#              . "of an unknown type: $_\n";
#        }
#      }
#      # Match a CTD19Plus header
#      elsif ( /^[\*\s]*SeacatPlus/ )
#      {
#        $ctdModel = "CTD19Plus";
#        ...
#      }
#
#
    if (
/^.*SEACAT PROFILER\s+\S+\s+\S+\s+\S+\s+(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)\.\d+.*/
      || /^.*SeacatPlus\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+).*/

      || /^.*SBE\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+).*/
      || /^.*SBE\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+).*/

        )
    {

      print "   $_";
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
      foreach my $deployment_record ( @{$sensor_deployment} )
      {

        #print "$deployment_record->{'time'}\n";
        if ( $deployment_record->{"time"} > $hex_time )
        {
          last;
        }
        $last_deployment_record = $deployment_record;
      }
      if ( $last_deployment_record == 0 )
      {
        print "argh! couldn't find a deployment record\n";
      }

      #print Dumper($last_deployment_record);
      $CTD_type = $last_deployment_record->{"CTD"};
      my $CTD_SN                      = $last_deployment_record->{"CTD_SN"};
      my $last_CTD_coefficient_record = 0;
      foreach my $CTD_coefficient_record (
                             @{ $sensor_coefficients->{$CTD_type}->{$CTD_SN} } )
      {
        if ( $CTD_coefficient_record->{"CTD_cal_date"} > $hex_time )
        {
          last;
        }
        $last_CTD_coefficient_record = $CTD_coefficient_record;
      }
      if ( $last_CTD_coefficient_record == 0 )
      {
        print "argh! couldn't find a CTD coefficient record\n";
      }
      $CTD_coefficients = $last_CTD_coefficient_record;

      #print "Whole shebang " . Dumper( $CTD_coefficients ) . "\n";
      my $V0_model = $last_deployment_record->{"V0_model"};
      my $V0_SN    = $last_deployment_record->{"V0_SN"};
      if ( $V0_model ne 'NA' )
      {
        my $last_V0_coefficient_record = 0;

#print "Whole shebang " . Dumper( $sensor_coefficients->{$V0_model}->{$V0_SN} ) . "\n";
        foreach my $V0_coefficient_record (
                              @{ $sensor_coefficients->{$V0_model}->{$V0_SN} } )
        {

  #print "Looking for $hex_time in: " . Dumper( $V0_coefficient_record ) . "\n";
          if ( $V0_coefficient_record->{"cal_date"} > $hex_time )
          {
            last;
          }
          $last_V0_coefficient_record = $V0_coefficient_record;
        }
        if ( $last_V0_coefficient_record == 0 )
        {
          print "argh! couldn't find a V0_coefficient record\n";
        }

        #print  " HERE AND " . ref($last_V0_coefficient_record) . "\n";
        $V0_coefficients = $last_V0_coefficient_record;

        #print Dumper($V0_coefficients);
      }
      my $V1_model = $last_deployment_record->{"V1_model"};
      my $V1_SN    = $last_deployment_record->{"V1_SN"};

      #print "V1 info: $V1_model, $V1_SN \n";
      if ( $V1_model ne 'NA' )
      {
        my $last_V1_coefficient_record = 0;
        foreach my $V1_coefficient_record (
                              @{ $sensor_coefficients->{$V1_model}->{$V1_SN} } )
        {
          if ( $V1_coefficient_record->{"cal_date"} > $hex_time )
          {
            last;
          }
          $last_V1_coefficient_record = $V1_coefficient_record;
        }
        if ( $last_V1_coefficient_record == 0 )
        {
          print "argh! couldn't find a V1_coefficient_record record\n";
        }
        $V1_coefficients = $last_V1_coefficient_record;

        #print Dumper($V1_coefficients);
      }
      my $V2_model = $last_deployment_record->{"V2_model"};
      my $V2_SN    = $last_deployment_record->{"V2_SN"};

      #print "V2 info: $V2_model, $V2_SN \n";
      if ( $V2_model ne 'NA' )
      {
        my $last_V2_coefficient_record = 0;
        foreach my $V2_coefficient_record (
                              @{ $sensor_coefficients->{$V2_model}->{$V2_SN} } )
        {
          if ( $V2_coefficient_record->{"cal_date"} > $hex_time )
          {
            last;
          }
          $last_V2_coefficient_record = $V2_coefficient_record;
        }
        if ( $last_V2_coefficient_record == 0 )
        {
          print "argh! couldn't find a V2_coefficient_record record\n";
        }
        $V2_coefficients = $last_V2_coefficient_record;

        #print Dumper($V2_coefficients);
      }
      my $V3_model = $last_deployment_record->{"V3_model"};
      my $V3_SN    = $last_deployment_record->{"V3_SN"};

#print "$V3_model $V3_SN \n";
#print "Whole shebang " . Dumper( $sensor_coefficients->{$V3_model}->{$V3_SN} ) . "\n";

      if ( $V3_model ne 'NA' )
      {
        my $last_V3_coefficient_record = 0;
        foreach my $V3_coefficient_record (
                              @{ $sensor_coefficients->{$V3_model}->{$V3_SN} } )
        {
          if ( $V3_coefficient_record->{"cal_date"} > $hex_time )
          {
            last;
          }
          $last_V3_coefficient_record = $V3_coefficient_record;
        }
        if ( $last_V3_coefficient_record == 0 )
        {
          print "argh! couldn't find a V3_coefficient_record record\n";
        }
        $V3_coefficients = $last_V3_coefficient_record;

        #print Dumper($V3_coefficients);
      }

      if ( $CTD_type eq "SBE19PlusV2" )
      {

        my $V4_model = $last_deployment_record->{"V4_model"};
        my $V4_SN    = $last_deployment_record->{"V4_SN"};

        #print "V4 info: $V4_model, $V4_SN \n";
        if ( $V4_model ne 'NA' )
        {
          my $last_V4_coefficient_record = 0;
          foreach my $V4_coefficient_record (
                              @{ $sensor_coefficients->{$V4_model}->{$V4_SN} } )
          {
            if ( $V4_coefficient_record->{"cal_date"} > $hex_time )
            {
              last;
            }
            $last_V4_coefficient_record = $V4_coefficient_record;
          }
          if ( $last_V4_coefficient_record == 0 )
          {
            print "argh! couldn't find a V4_coefficient_record record\n";
          }
          $V4_coefficients = $last_V4_coefficient_record;

          #print Dumper($V4_coefficients);
        }

        my $V5_model = $last_deployment_record->{"V5_model"};
        my $V5_SN    = $last_deployment_record->{"V5_SN"};

        #print "V5 info: $V5_model, $V5_SN \n";
        if ( $V5_model ne 'NA' )
        {
          my $last_V5_coefficient_record = 0;
          foreach my $V5_coefficient_record (
                              @{ $sensor_coefficients->{$V5_model}->{$V5_SN} } )
          {
            if ( $V5_coefficient_record->{"cal_date"} > $hex_time )
            {
              last;
            }
            $last_V5_coefficient_record = $V5_coefficient_record;
          }
          if ( $last_V5_coefficient_record == 0 )
          {
            print "argh! couldn't find a V5_coefficient_record record\n";
          }
          $V5_coefficients = $last_V5_coefficient_record;

          #print Dumper($V5_coefficients);
        }

        my $CTDSerial_model = $last_deployment_record->{"CTDSerial_model"};
        my $CTDSerial_SN    = $last_deployment_record->{"CTDSerial_SN"};

        #print "CTDSerial info: $CTDSerial_model, $CTDSerial_SN \n";
        if ( $CTDSerial_model ne 'NA' )
        {
          my $last_CTDSerial_coefficient_record = 0;
          foreach my $CTDSerial_coefficient_record (
                @{ $sensor_coefficients->{$CTDSerial_model}->{$CTDSerial_SN} } )
          {
            if ( $CTDSerial_coefficient_record->{"cal_date"} > $hex_time )
            {
              last;
            }
            $last_CTDSerial_coefficient_record = $CTDSerial_coefficient_record;
          }
          if ( $last_CTDSerial_coefficient_record == 0 )
          {
            print "argh! couldn't find a CTDSerial_coefficient_record record\n";
          }
          $CTDSerial_coefficients = $last_CTDSerial_coefficient_record;

          #print Dumper($CTDSerial_coefficients);
        }

      }

    }

    #print "CTD type = $CTD_type\n";
    #print "LINE = $_\n";
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

    if ( /.*SeaFET\s*=\s*(yes).*/ )
    {
      $SeaFET_present = "YES";

      #print "SeaFET = $SeaFET_present\n";
    }

    if ( $CTD_type eq "SBE19" )
    {
      #
      #
      # Read hex data lines, interpret reference scans and data
      #
      #
      #
      # TODO: flag bad reference or data scans
      #
      if ( /^([A-F0-9]{24,24})\s*$/ )
      {
        $hex_line = $1;

        #print "HEX LINE = $hex_line \n";
        if ( /^05/ )
        {
          $ref_scans_index++;
          $ref_scans[ $ref_scans_index ]->{"RefHigh"} =
              hex2dec( substr( $hex_line, 2, 6, ), 0 ) / 256;
          $cnv_data[ $hex_data_index ]->{"Ref_scan_index"}  = $ref_scans_index;
          $cnv_data[ $hex_data_index ]->{"Data_scan_index"} = 0;
          $cnv_data[ $hex_data_index ]->{"IsRef"}           = 1;

          # Interpret data line
          $cnv_data[ $hex_data_index ]->{"pressure_raw"} =
              hex2decref( substr( $hex_line, 20, 4 ) );
          $cnv_data[ $hex_data_index ]->{"Raw_Temp_freq"} = "NAN";
          $cnv_data[ $hex_data_index ]->{"Raw_Cond_freq"} = "NAN";
          $cnv_data[ $hex_data_index ]->{"V0_raw"} =
              hex2dec( substr( $hex_line, 8, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V1_raw"} =
              hex2dec( substr( $hex_line, 11, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V2_raw"} =
              hex2dec( substr( $hex_line, 14, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V3_raw"} =
              hex2dec( substr( $hex_line, 17, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
          $hex_data_index++;
        } elsif ( /^FF/ )
        {
          $ref_scans[ $ref_scans_index ]->{"RefLow"} =
              hex2dec( substr( $hex_line, 2, 6, ), 0 ) / 256;
          $cnv_data[ $hex_data_index ]->{"Ref_scan_index"}  = $ref_scans_index;
          $cnv_data[ $hex_data_index ]->{"Data_scan_index"} = 1;
          $cnv_data[ $hex_data_index ]->{"IsRef"}           = 2;

          # Interpret data line
          $cnv_data[ $hex_data_index ]->{"pressure_raw"} =
              hex2decref( substr( $hex_line, 20, 4 ) );
          $cnv_data[ $hex_data_index ]->{"Raw_Temp_freq"} = "NAN";
          $cnv_data[ $hex_data_index ]->{"Raw_Cond_freq"} = "NAN";
          $cnv_data[ $hex_data_index ]->{"V0_raw"} =
              hex2dec( substr( $hex_line, 8, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V1_raw"} =
              hex2dec( substr( $hex_line, 11, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V2_raw"} =
              hex2dec( substr( $hex_line, 14, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V3_raw"} =
              hex2dec( substr( $hex_line, 17, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
          $hex_data_index++;
          $data_scan_index  = 2;
          $has_reference_19 = 1;
        } else
        {
          # Store reference scan index and data scan index
          if ( $has_reference_19 == 1 )
          {
            $cnv_data[ $hex_data_index ]->{"Data_scan_index"} =
                ( $data_scan_index );
            $cnv_data[ $hex_data_index ]->{"Ref_scan_index"} =
                ( $ref_scans_index );
          } else
          {
            $cnv_data[ $hex_data_index ]->{"Data_scan_index"} = 0;
            $cnv_data[ $hex_data_index ]->{"Ref_scan_index"}  = 0;
          }

          # Interpret data line
          $cnv_data[ $hex_data_index ]->{"IsRef"} = 0;
          $cnv_data[ $hex_data_index ]->{"pressure_raw"} =
              hex2dec( substr( $hex_line, 20, 4 ), 1 );
          $cnv_data[ $hex_data_index ]->{"Raw_Temp_freq"} =
              ( hex2dec( substr( $hex_line, 0, 4 ), 0 ) / 17 ) + 1950;
          $cnv_data[ $hex_data_index ]->{"Raw_Cond_freq"} =
              sqrt(
                 ( hex2dec( substr( $hex_line, 4, 4 ), 0 ) ) * 2900 + 6250000 );
          $cnv_data[ $hex_data_index ]->{"V0_raw"} =
              hex2dec( substr( $hex_line, 8, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V1_raw"} =
              hex2dec( substr( $hex_line, 11, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V2_raw"} =
              hex2dec( substr( $hex_line, 14, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"V3_raw"} =
              hex2dec( substr( $hex_line, 17, 3 ), 0 ) / 819;
          $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
          $hex_data_index++;
          $data_scan_index++;
        }
      }
    } elsif ( $CTD_type eq "SBE19Plus" )
    {

      #
      #
      # Interpret data lines (no reference scans or corrections)
      #
      #
      if ( /^([A-F0-9]{38,38})\s*$/ )
      {

        # interpret DATA and STORE
        $hex_line = $1;

        #print "HEX LINE == $hex_line\n";
        $cnv_data[ $hex_data_index ]->{"Temp_raw"} =
            hex2dec( substr( $hex_line, 0, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Cond_raw"} =
            hex2dec( substr( $hex_line, 6, 6 ), 0 ) / 256;
        $cnv_data[ $hex_data_index ]->{"Press_raw"} =
            hex2dec( substr( $hex_line, 12, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Press_Temp_raw"} =
            hex2dec( substr( $hex_line, 18, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V0_raw"} =
            hex2dec( substr( $hex_line, 22, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V1_raw"} =
            hex2dec( substr( $hex_line, 26, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V2_raw"} =
            hex2dec( substr( $hex_line, 30, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V3_raw"} =
            hex2dec( substr( $hex_line, 34, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
        $hex_data_index++;
      } elsif ( /^([A-F0-9]{34,34})\s*$/ )
      {
        $hex_line = $1;

        #print "HEX LINE == $hex_line\n";
        $cnv_data[ $hex_data_index ]->{"Temp_raw"} =
            hex2dec( substr( $hex_line, 0, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Cond_raw"} =
            hex2dec( substr( $hex_line, 6, 6 ), 0 ) / 256;
        $cnv_data[ $hex_data_index ]->{"Press_raw"} =
            hex2dec( substr( $hex_line, 12, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Press_Temp_raw"} =
            hex2dec( substr( $hex_line, 18, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V0_raw"} =
            hex2dec( substr( $hex_line, 22, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V1_raw"} =
            hex2dec( substr( $hex_line, 26, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V2_raw"} =
            hex2dec( substr( $hex_line, 30, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
        $hex_data_index++;
      }
    } elsif ( ( $CTD_type eq "SBE19PlusV2" ) && ( $SeaFET_present eq "NO" ) )
    {

      #
      #
      # Interpret data lines (no reference scans or corrections)
      #
      #
      if ( /^([A-F0-9]{46,46})\s*$/ )
      {

        # interpret DATA and STORE
        $hex_line = $1;

        #print "HEX LINE == $hex_line\n";
        $cnv_data[ $hex_data_index ]->{"Temp_raw"} =
            hex2dec( substr( $hex_line, 0, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Cond_raw"} =
            hex2dec( substr( $hex_line, 6, 6 ), 0 ) / 256;
        $cnv_data[ $hex_data_index ]->{"Press_raw"} =
            hex2dec( substr( $hex_line, 12, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Press_Temp_raw"} =
            hex2dec( substr( $hex_line, 18, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V0_raw"} =
            hex2dec( substr( $hex_line, 22, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V1_raw"} =
            hex2dec( substr( $hex_line, 26, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V2_raw"} =
            hex2dec( substr( $hex_line, 30, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V3_raw"} =
            hex2dec( substr( $hex_line, 34, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V4_raw"} =
            hex2dec( substr( $hex_line, 38, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V5_raw"} =
            hex2dec( substr( $hex_line, 42, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
        $hex_data_index++;
      }
    } elsif ( ( $CTD_type eq "SBE19PlusV2" ) && ( $SeaFET_present eq "YES" ) )
    {

      #
      #
      # Interpret data lines (no reference scans or corrections)
      #
      #
      if ( /^([A-F0-9]{58,58})\s*$/ )
      {

        # interpret DATA and STORE
        $hex_line = $1;

        #print "HEX LINE == $hex_line\n";
        $cnv_data[ $hex_data_index ]->{"Temp_raw"} =
            hex2dec( substr( $hex_line, 0, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Cond_raw"} =
            hex2dec( substr( $hex_line, 6, 6 ), 0 ) / 256;
        $cnv_data[ $hex_data_index ]->{"Press_raw"} =
            hex2dec( substr( $hex_line, 12, 6 ), 0 );
        $cnv_data[ $hex_data_index ]->{"Press_Temp_raw"} =
            hex2dec( substr( $hex_line, 18, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V0_raw"} =
            hex2dec( substr( $hex_line, 22, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V1_raw"} =
            hex2dec( substr( $hex_line, 26, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V2_raw"} =
            hex2dec( substr( $hex_line, 30, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V3_raw"} =
            hex2dec( substr( $hex_line, 34, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V4_raw"} =
            hex2dec( substr( $hex_line, 38, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V5_raw"} =
            hex2dec( substr( $hex_line, 42, 4 ), 0 ) / 13107;
        $cnv_data[ $hex_data_index ]->{"V_ISFET_INT_raw"} =
            ( hex2dec( substr( $hex_line, 46, 6 ), 0 ) / 1000000 ) - 8;
        $cnv_data[ $hex_data_index ]->{"V_ISFET_EXT_raw"} =
            ( hex2dec( substr( $hex_line, 52, 6 ), 0 ) / 1000000 ) - 8;
        $cnv_data[ $hex_data_index ]->{"Scan"} = $hex_data_index + 1;
        $hex_data_index++;
      }
    }

  }
  close( IN );

  #
  # RMH: Here would be a nice place to break this subroutine into
  #      two logical subroutines.  The first to parse and store the
  #      raw HEX data based on the file format.  The second to
  #      postprocess the data.
  #

  ## SBE19 CTDs
  if ( $CTD_type eq "SBE19" )
  {
    #print "uncorrected frequency cnv data: ".Dumper(\@cnv_data)."\n";
    #print "reference scans before interpolation: ".Dumper(\@ref_scans)."\n";

    # There are two steps to converting the raw data into engineering units,
    # due to a convoluted algorithm seabird uses involving reference scan
    # interpolations. The first step is to interpolate the reference scan
    # data through all the hex data lines. The second step is to go through
    # each record and correct the temp and cond frequencies,
    # interpolating these frequencies through the lines that contained
    # reference scans, then converting everything into engineering units.

    #
    # Step 1: Interpolate correction between reference scans
    #
    my $Ref_High_int   = 0;
    my $Ref_Low_int    = 0;
    my $Ref_High_final = 0;
    my $Ref_Low_final  = 0;

    foreach my $cnv_record ( @cnv_data )
    {    ### OPEN 'FOREACH REF SCAN INTERP LOOP' ###

      if ( $#ref_scans == $cnv_record->{"Ref_scan_index"} )
      {
        $Ref_High_int = 0;
      } else
      {
        $Ref_High_int = (
              (
                $ref_scans[ $cnv_record->{"Ref_scan_index"} + 1 ]->{"RefHigh"} -
                    $ref_scans[ $cnv_record->{"Ref_scan_index"} ]->{"RefHigh"}
              ) / 120
            ) *
            $cnv_record->{"Data_scan_index"};
      }
      $Ref_High_final =
          $ref_scans[ $cnv_record->{"Ref_scan_index"} ]->{"RefHigh"} +
          $Ref_High_int;

      if ( $#ref_scans == $cnv_record->{"Ref_scan_index"} )
      {
        $Ref_Low_int = 0;
      } else
      {
        $Ref_Low_int = (
               (
                 $ref_scans[ $cnv_record->{"Ref_scan_index"} + 1 ]->{"RefLow"} -
                     $ref_scans[ $cnv_record->{"Ref_scan_index"} ]->{"RefLow"}
               ) / 120
            ) *
            $cnv_record->{"Data_scan_index"};
      }

      $Ref_Low_final =
          $ref_scans[ $cnv_record->{"Ref_scan_index"} ]->{"RefLow"} +
          $Ref_Low_int;

      #print $Ref_High_int."\n"
      #print $Ref_High_final."\n";
      #print $cnv_record->{"Data_scan_index"}."\n";
      $cnv_record->{"Ref_High_int"}   = $Ref_High_int;
      $cnv_record->{"Ref_High_final"} = $Ref_High_final;
      $cnv_record->{"Ref_Low_int"}    = $Ref_Low_int;
      $cnv_record->{"Ref_Low_final"}  = $Ref_Low_final;
      $cnv_record->{"Ref_High_orig"} =
          $ref_scans[ $cnv_record->{"Ref_scan_index"} ]->{"RefHigh"};
      $cnv_record->{"Ref_Low_orig"} =
          $ref_scans[ $cnv_record->{"Ref_scan_index"} ]->{"RefLow"};

      #print "High Freq int ==: $Ref_High_int\n";
      #print "High Freq final ==: $Ref_High_final\n";
      #print "Low Freq int ==: $Ref_Low_int\n";
      #print "Low Freq final ==: $Ref_Low_final\n";
      #print "Ref High orig ==:".$cnv_record->{"Ref_High_orig"}."\n";
      #print "Ref Low orig ==:".$cnv_record->{"Ref_Low_orig"}."\n";

      #
      # Frequency correction factors
      #
      $freq_cor_a =
          ( ( $Ref_High_final**2 ) - ( $Ref_Low_final**2 ) ) / $freq_cor_X3;

      #print "Freq cor A ==: $freq_cor_a \n";
      if ( $freq_cor_a < 0.5 )
      {
        $cnv_record->{"freq_cor_a"} = 1;
      } else
      {
        $cnv_record->{"freq_cor_a"} = $freq_cor_a;
      }
      $freq_cor_b = $Ref_Low_final**2 - ( $freq_cor_a / $freq_cor_X2 );

      #print "Freq cor B ==: $freq_cor_b \n";
      if ( $freq_cor_b > 1000000 )
      {
        $cnv_record->{"freq_cor_b"} = 0;
      } else
      {
        $cnv_record->{"freq_cor_b"} = $freq_cor_b;
      }

    }    ### CLOSE 'FOREACH REF SCAN INTERP LOOP' ###

#
# Step 2: go through each record and apply frequency corrections, or interpolate
# frequencies through reference scans, and convert raw data into engineering units
#

    for ( my $i = 0 ; $i <= $#cnv_data ; $i++ )
    {    ### OPEN 'FOR SBE19 RECORD PROCESS LOOP' ###
      if ( @cnv_data[ $i ]->{"IsRef"} > 0 )
      {
#
# Define first and last point of interpolation (same points for both reference scans, but
# the distance from $i changes between the two lines)
#
        my $freq1I = 0;
        my $freq4I = 0;
        if ( @cnv_data[ $i ]->{"IsRef"} == 1 )
        {
          $freq1I = $i - 1;
          $freq4I = $i + 2;
        } elsif ( @cnv_data[ $i ]->{"IsRef"} == 2 )
        {
          $freq1I = $i - 2;
          $freq4I = $i + 1;
        }
        @cnv_data[ $i ]->{"freq1I"} = $freq1I;
        @cnv_data[ $i ]->{"freq4I"} = $freq4I;
        if ( $#cnv_data >= $freq4I )
        {
 #
 # Retrieve first point of interpolation (corrected, untruncated temp frequency)
 #
          my $temp_freq1 = @cnv_data[ $freq1I ]->{"Temp_freq"};
          @cnv_data[ $i ]->{"temp_freq1"} = $temp_freq1;
#
# Retrieve last point of interpolation (uncorrected temp frequency) and correct using reference scan
# correction corresponding to $i (NOT using the reference scans correction that corresponds with the
# uncorrected temp frequency)
#
          my $temp_freq4 = sqrt(
                            (
                              (
                                ( @cnv_data[ $freq4I ]->{"Raw_Temp_freq"}**2 ) -
                                    @cnv_data[ $i ]->{"freq_cor_b"}
                              ) / @cnv_data[ $i ]->{"freq_cor_a"}
                            ) - $freq_cor_PC
          );
          @cnv_data[ $i ]->{"temp_freq4"} = $temp_freq4;
          #
          # Interpolate temp freq for $i and store value and truncated value
          #
          my $temp_freq =
              $temp_freq1 +
              (
                ( @cnv_data[ $i ]->{"IsRef"} * ( $temp_freq4 - $temp_freq1 ) ) /
                    3 );

          # Old
          #@cnv_data[ $i ]->{"Temp_freq"} = $temp_freq;
          #@cnv_data[ $i ]->{"Temp_freq_seabird"} =
          #    seabird_truncRound( $temp_freq );
          if ( $useSeabirdTruncation )
          {
            @cnv_data[ $i ]->{"Temp_freq"} =
                seabird_truncRound( $temp_freq );
          } else
          {
            @cnv_data[ $i ]->{"Temp_freq"} = $temp_freq;
          }

          #
          # Retrieve first point of interpolation (corrected,
          # untruncated cond frequency)
          #
          my $cond_freq1 = @cnv_data[ $freq1I ]->{"Cond_freq"};
          @cnv_data[ $i ]->{"cond_freq1"} = $cond_freq1;

          #
          # Retrieve last point of interpolation (uncorrected cond
          # frequency) and correct using reference scan
          # correction corresponding to $i (NOT using the
          # reference scans correction that corresponds with the
          # uncorrected cond frequency)
          #
          my $cond_freq4 = sqrt(
                            (
                              (
                                ( @cnv_data[ $freq4I ]->{"Raw_Cond_freq"}**2 ) -
                                    @cnv_data[ $i ]->{"freq_cor_b"}
                              ) / @cnv_data[ $i ]->{"freq_cor_a"}
                            ) - $freq_cor_PC
          );
          @cnv_data[ $i ]->{"cond_freq4"} = $cond_freq4;
          #
          # Interpolate cond freq for $i and store value and truncated value
          #
          my $cond_freq =
              $cond_freq1 +
              (
                ( @cnv_data[ $i ]->{"IsRef"} * ( $cond_freq4 - $cond_freq1 ) ) /
                    3 );
          if ( $useSeabirdTruncation )
          {
            @cnv_data[ $i ]->{"Cond_freq"} =
                seabird_truncRound( $cond_freq );
          } else
          {
            @cnv_data[ $i ]->{"Cond_freq"} = $cond_freq;
          }
        } else
        {

          my $temp_freq = sqrt(
                            (
                              (
                                ( @cnv_data[ $freq1I ]->{"Raw_Temp_freq"}**2 ) -
                                    @cnv_data[ $i ]->{"freq_cor_b"}
                              ) / @cnv_data[ $i ]->{"freq_cor_a"}
                            ) - $freq_cor_PC
          );
          if ( $useSeabirdTruncation )
          {
            @cnv_data[ $i ]->{"Temp_freq"} =
                seabird_truncRound( $temp_freq );
          } else
          {
            @cnv_data[ $i ]->{"Temp_freq"} = $temp_freq;
          }
          my $cond_freq = sqrt(
                            (
                              (
                                ( @cnv_data[ $freq1I ]->{"Raw_Cond_freq"}**2 ) -
                                    @cnv_data[ $i ]->{"freq_cor_b"}
                              ) / @cnv_data[ $i ]->{"freq_cor_a"}
                            ) - $freq_cor_PC
          );
          if ( $useSeabirdTruncation )
          {
            @cnv_data[ $i ]->{"Cond_freq"} =
                seabird_truncRound( $cond_freq );
          } else
          {
            @cnv_data[ $i ]->{"Cond_freq"} = $cond_freq;
          }

        }

      } elsif ( @cnv_data[ $i ]->{"IsRef"} == 0 )
      {
        #
        # Correct raw temp frequency
        #

        my $temp_freq = sqrt(
                              (
                                (
                                  ( @cnv_data[ $i ]->{"Raw_Temp_freq"}**2 ) -
                                      @cnv_data[ $i ]->{"freq_cor_b"}
                                ) / @cnv_data[ $i ]->{"freq_cor_a"}
                              ) - $freq_cor_PC
        );

        #
        # Store value and truncated value
        #
        if ( $useSeabirdTruncation )
        {
          @cnv_data[ $i ]->{"Temp_freq"} =
              seabird_truncRound( $temp_freq );
        } else
        {
          @cnv_data[ $i ]->{"Temp_freq"} = $temp_freq;
        }

        #
        # Correct raw cond frequency
        #
        my $cond_freq = sqrt(
                              (
                                (
                                  ( @cnv_data[ $i ]->{"Raw_Cond_freq"}**2 ) -
                                      @cnv_data[ $i ]->{"freq_cor_b"}
                                ) / @cnv_data[ $i ]->{"freq_cor_a"}
                              ) - $freq_cor_PC
        );
        #
        # Store value and truncated value
        #
        if ( $useSeabirdTruncation )
        {
          @cnv_data[ $i ]->{"Cond_freq"} =
              seabird_truncRound( $cond_freq );
        } else
        {
          @cnv_data[ $i ]->{"Cond_freq"} = $cond_freq;
        }
      }
      #
      # Calculate Parameters
      #
      #
      # Pressure
      #
      my $Press =
          $CTD_coefficients->{"press_A0"} +
          $CTD_coefficients->{"press_A1"} *
          @cnv_data[ $i ]->{"pressure_raw"} +
          $CTD_coefficients->{"press_A2"} *
          @cnv_data[ $i ]->{"pressure_raw"}**2;
      @cnv_data[ $i ]->{"Press"}      = $Press;
      @cnv_data[ $i ]->{"Press_psia"} = ( $Press );
      @cnv_data[ $i ]->{"Press_psi"}  = ( $Press - 14.7 );
      @cnv_data[ $i ]->{"Press_db"}   = ( ( $Press - 14.7 ) * 0.689476 );

      @cnv_data[ $i ]->{"Depth"} =
          calcDepth( @cnv_data[ $i ]->{"Press_db"}, $latitude );

      #
      # Temperature
      #
      # In 1995 Seabird switched from the T68 temperature standard to the
      # T90 standard.  The formula for conversion is the same however the
      # calibration coefficients are different. The "a-d" + f0 coefficients
      # are used for T68 and the "g-j" + f0 coefficients are for T90.
      # The formula below is hardcoded for use with T90 coefficients.
      # TODO: Make code compatible with SBE19 data files pre January 1995
      # which use the T68 coefficients only.
      #
      @cnv_data[ $i ]->{"Temp"} = 1 / (
             $CTD_coefficients->{"temp_g"} + $CTD_coefficients->{"temp_h"} * (
               log(
                 $CTD_coefficients->{"temp_f0"} / @cnv_data[ $i ]->{"Temp_freq"}
               )
                 ) + $CTD_coefficients->{"temp_i"} * (
               log(
                 $CTD_coefficients->{"temp_f0"} / @cnv_data[ $i ]->{"Temp_freq"}
               )
                 )**2 + $CTD_coefficients->{"temp_j"} * (
               log(
                 $CTD_coefficients->{"temp_f0"} / @cnv_data[ $i ]->{"Temp_freq"}
               )
                 )**3
      ) - 273.15;    # ITPS-90

      # New convention @cnv_data[ $i ]->{"Temp"} will always be in ITPS-68 by
      # default.  So go and convert it now.
      @cnv_data[ $i ]->{"Temp"} = @cnv_data[ $i ]->{"Temp"} * 1.00024; # ITPS-68

    #
    # Conductivity
    #
    # Divide frequency by 1000 to get in kHz (needed to convert to conductivity)
      my $Cond_freq_kHz = @cnv_data[ $i ]->{"Cond_freq"} / 1000;
      @cnv_data[ $i ]->{"Cond"} =
          ( $CTD_coefficients->{"cond_g"} +
            ( $CTD_coefficients->{"cond_h"} * ( $Cond_freq_kHz**2 ) ) +
            ( $CTD_coefficients->{"cond_i"} * ( $Cond_freq_kHz**3 ) ) +
            ( $CTD_coefficients->{"cond_j"} * ( $Cond_freq_kHz**4 ) ) ) / (
         10 * (
           1 + ( $CTD_coefficients->{"cond_CTcor"} * @cnv_data[ $i ]->{"Temp"} )
               + (
               $CTD_coefficients->{"cond_CPcor"} * @cnv_data[ $i ]->{"Press_db"}
               )
         )
            );

      #
      # Salinity
      #
      @cnv_data[ $i ]->{"Salinity"} =
          cond2sal( @cnv_data[ $i ]->{"Temp"},
                    @cnv_data[ $i ]->{"Press_db"},
                    @cnv_data[ $i ]->{"Cond"}, "T68" );

      #
      # Calculate Sigmas
      #
      my $sigmaTheta = calcSigmaTheta(
                                       @cnv_data[ $i ]->{"Salinity"},
                                       @cnv_data[ $i ]->{"Temp"},
                                       "T68",
                                       @cnv_data[ $i ]->{"Press_db"}
      );
      @cnv_data[ $i ]->{"SigmaTheta"} = $sigmaTheta;

      my $sigmaT = Density( @cnv_data[ $i ]->{"Salinity"},
                            @cnv_data[ $i ]->{"Temp"},
                            "T68", 0 );
      @cnv_data[ $i ]->{"SigmaT"} = $sigmaT;

      #
      # Sigma-t
      #
      #if ( $useSeabirdTruncation )
      #{
      #  @cnv_data[ $i ]->{"SigmaT"} =
      #      calcSigma( @cnv_data[ $i ]->{"Salinity"},
      #                 @cnv_data[ $i ]->{"Temp"},
      #                 0, "T68" );
      #} else
      #{
      #  @cnv_data[ $i ]->{"SigmaT"} =
      #      calcSigma( @cnv_data[ $i ]->{"Salinity"},
      #                 @cnv_data[ $i ]->{"Temp"},
      #                 @cnv_data[ $i ]->{"Press_db"}, "T68" );
      #}

      #
      # Aux voltages:
      # For each aux voltage we need to do several things.  First
      # we need to determine what type of device is attached to this
      # port.  Second we need to determine the calibration
      # coeficients for the device, and third we need to calculate the
      # engineering units based on the first two.
      #
      # V0
      #
      $V0_type = $last_deployment_record->{"V0_type"};

      #print "V0 type = $V0_type\n";

      $coefficients{"$V0_type"} = $V0_coefficients;
      if ( $V0_type ne "NA" )
      {
        my $V0_calc = auxVolt_calc(
                                    @cnv_data[ $i ]->{"V0_raw"},
                                    $V0_type,
                                    $V0_coefficients,
                                    @cnv_data[ $i ]->{"Salinity"},
                                    @cnv_data[ $i ]->{"Temp"},
                                    @cnv_data[ $i ]->{"Press_db"},
                                    "T68"
        );
        @cnv_data[ $i ]->{ $V0_type . "_volts" } =
            @cnv_data[ $i ]->{"V0_raw"};
        @cnv_data[ $i ]->{$V0_type} = $V0_calc;
      } else
      {
        @cnv_data[ $i ]->{"V0_volts"} = @cnv_data[ $i ]->{"V0_raw"};
      }
      #
      # V1
      #
      $V1_type = $last_deployment_record->{"V1_type"};

      #print "V1 type = $V1_type\n";

      $coefficients{"$V1_type"} = $V1_coefficients;
      if ( $V1_type ne "NA" )
      {
        my $V1_calc = auxVolt_calc(
                                    @cnv_data[ $i ]->{"V1_raw"},
                                    $V1_type,
                                    $V1_coefficients,
                                    @cnv_data[ $i ]->{"Salinity"},
                                    @cnv_data[ $i ]->{"Temp"},
                                    @cnv_data[ $i ]->{"Press_db"},
                                    "T68"
        );
        @cnv_data[ $i ]->{ $V1_type . "_volts" } =
            @cnv_data[ $i ]->{"V1_raw"};
        @cnv_data[ $i ]->{$V1_type} = $V1_calc;
      } else
      {
        @cnv_data[ $i ]->{"V1_volts"} = @cnv_data[ $i ]->{"V1_raw"};
      }
      #
      # V2
      #
      $V2_type = $last_deployment_record->{"V2_type"};

      #print "V2 type = $V2_type\n";

      $coefficients{"$V2_type"} = $V2_coefficients;
      if ( $V2_type ne "NA" )
      {
        my $V2_calc = auxVolt_calc(
                                    @cnv_data[ $i ]->{"V2_raw"},
                                    $V2_type,
                                    $V2_coefficients,
                                    @cnv_data[ $i ]->{"Salinity"},
                                    @cnv_data[ $i ]->{"Temp"},
                                    @cnv_data[ $i ]->{"Press_db"},
                                    "T68"
        );
        @cnv_data[ $i ]->{ $V2_type . "_volts" } =
            @cnv_data[ $i ]->{"V2_raw"};
        @cnv_data[ $i ]->{$V2_type} = $V2_calc;
      } else
      {
        @cnv_data[ $i ]->{"V2_volts"} = @cnv_data[ $i ]->{"V2_raw"};
      }
      #
      # V3
      #
      $V3_type = $last_deployment_record->{"V3_type"};

      #print "V3 type = $V3_type\n";

      $coefficients{"$V3_type"} = $V3_coefficients;
      if ( $V3_type ne "NA" )
      {
        my $V3_calc = auxVolt_calc(
                                    @cnv_data[ $i ]->{"V3_raw"},
                                    $V3_type,
                                    $V3_coefficients,
                                    @cnv_data[ $i ]->{"Salinity"},
                                    @cnv_data[ $i ]->{"Temp"},
                                    @cnv_data[ $i ]->{"Press_db"},
                                    "T68"
        );
        @cnv_data[ $i ]->{ $V3_type . "_volts" } =
            @cnv_data[ $i ]->{"V3_raw"};
        @cnv_data[ $i ]->{$V3_type} = $V3_calc;
      } else
      {
        @cnv_data[ $i ]->{"V3_volts"} = @cnv_data[ $i ]->{"V3_raw"};
      }

      #
      # Convert Oxygen into units
      #
      my $round_O2 = sprintf( "%6.5f", @cnv_data[ $i ]->{"O2"} );
      @cnv_data[ $i ]->{"O2_mg"} = $round_O2 * 1.4291;

      @cnv_data[ $i ]->{"O2_umol"} =
          ( 44660 / ( @cnv_data[ $i ]->{"SigmaTheta"} + 1000 ) ) * $round_O2;

     # Derived formula
     #@cnv_data[ $i ]->{"O2_umol"} = (
     #                                 @cnv_data[ $i ]->{"O2"} / (
     #                                        (
     #                                          calcSigma(
     #                                            @cnv_data[ $i ]->{"Salinity"},
     #                                            @cnv_data[ $i ]->{"Temp"},
     #                                            @cnv_data[ $i ]->{"Press_db"},
     #                                            "T68"
     #                                          ) / 1000
     #                                        ) + 1
     #                                 )
     #) * 44.6596;

      #if ( $useSeabirdTruncation )
      #{
      #  my $round_SigmaT =
      #      sprintf( "%6.5f", @cnv_data[ $i ]->{"SigmaT"} );
      #
      #  @cnv_data[ $i ]->{"O2_umol"} =
      #      ( 44660 / ( $round_SigmaT + 1000 ) ) * $round_O2;
      #}

      @cnv_data[ $i ]->{"O2_sat_ml"} =
          Oxysat( @cnv_data[ $i ]->{"Salinity"},
                  @cnv_data[ $i ]->{"Temp"},
                  "T68", "ml/l" );

      @cnv_data[ $i ]->{"O2_sat_mgL"} =
          Oxysat( @cnv_data[ $i ]->{"Salinity"},
                  @cnv_data[ $i ]->{"Temp"},
                  "T68", "ml/l" ) * 1.4291;

    }    # end...for ( my $i = 0 ; $i <= $#cnv_data ...

  }    # end...if ( $CTD_type eq "SBE19"...
       #
       # SBE19Plus or SBE19PlusV2
       #
  elsif ( ( $CTD_type eq "SBE19Plus" ) || ( $CTD_type eq "SBE19PlusV2" ) )
  {
    # Finish calculating and storing
    foreach my $cnv_record ( @cnv_data )
    {

      #
      # Calculate Pressure
      #
      my $press_equ_1 =
          $CTD_coefficients->{"press_PTempPA0"} +
          ( $CTD_coefficients->{"press_PTempPA1"} *
            $cnv_record->{"Press_Temp_raw"} ) +
          ( $CTD_coefficients->{"press_PTempPA2"} *
            $cnv_record->{"Press_Temp_raw"}**2 );
      my $press_equ_2 =
          $cnv_record->{"Press_raw"} -
          $CTD_coefficients->{"press_PTCA0"} -
          $CTD_coefficients->{"press_PTCA1"} * $press_equ_1 -
          $CTD_coefficients->{"press_PTCA2"} * $press_equ_1**2;
      my $press_equ_3 =
          $press_equ_2 *
          $CTD_coefficients->{"press_PTCB0"} /
          ( $CTD_coefficients->{"press_PTCB0"} +
            $CTD_coefficients->{"press_PTCB1"} * $press_equ_1 +
            $CTD_coefficients->{"press_PTCB2"} * $press_equ_1**2 );
      my $Press_psia =
          $CTD_coefficients->{"press_PA0"} +
          $CTD_coefficients->{"press_PA1"} * $press_equ_3 +
          $CTD_coefficients->{"press_PA2"} * $press_equ_3**2;

      $cnv_record->{"Press_psia"} = $Press_psia;
      $cnv_record->{"Press_psi"}  = $Press_psia - 14.7;
      $cnv_record->{"Press_db"}   = ( ( $Press_psia - 14.7 ) * 0.689476 );

      # Calculate depth
      $cnv_record->{"Depth"} =
          calcDepth( $cnv_record->{"Press_db"}, $latitude );

      #
      # Temperature
      #
      # The SBE19Plus and SBE19PlusV2 ( all manufacturing dates ) are
      # based on the ITS-90 temperature standard.
      #
      # Their calibration sheets include a0-a3 ITS-90 coefficients
      # and include the following formulas for MV ( temp_equ_1 )
      # R ( temp_equ_2 ) and Temp.
      #
      # NOTE: Seabird uses T68 temperatures in it's salinity and other
      #       seawater calculations.
      #
      my $temp_equ_1 =
          ( ( $cnv_record->{"Temp_raw"} - 524288 ) / 1.6e+07 );
      my $temp_equ_2 =
          ( ( $temp_equ_1 * 2.9e+09 ) + 1.024e+08 ) /
          ( 2.048e+04 - $temp_equ_1 * 2.0e+05 );
      my $Temp =
          1 / ( $CTD_coefficients->{"temp_a0"} +
              ( $CTD_coefficients->{"temp_a1"} * log( $temp_equ_2 ) ) +
              ( $CTD_coefficients->{"temp_a2"} * ( log( $temp_equ_2 ) )**2 ) +
              ( $CTD_coefficients->{"temp_a3"} * ( log( $temp_equ_2 ) )**3 ) ) -
          273.15;
      $cnv_record->{"Temp"} = $Temp;    # ITS-90

      #print "T90 temp = "
      #    . $cnv_record->{"Temp"}
      #    . " T68 temp = "
      #    . ( $cnv_record->{"Temp"} * 1.00024 ) . "\n";

      # New convention $cnv_record->{"Temp"} will always be in ITPS-68 by
      # default.  So go and convert it now.
      $cnv_record->{"Temp"} = $cnv_record->{"Temp"} * 1.00024;    # ITPS-68

      #
      # Calculate conductivity
      #
      my $cond_freq = $cnv_record->{"Cond_raw"} / 1000;
      my $Cond =
          ( $CTD_coefficients->{"cond_g"} +
            ( $CTD_coefficients->{"cond_h"} * $cond_freq**2 ) +
            ( $CTD_coefficients->{"cond_i"} * $cond_freq**3 ) +
            ( $CTD_coefficients->{"cond_j"} * $cond_freq**4 ) ) /
          ( 1 + $CTD_coefficients->{"cond_CTcor"} * $cnv_record->{"Temp"} +
            $CTD_coefficients->{"cond_CPcor"} * $cnv_record->{"Press_db"} );

      $cnv_record->{"Cond"} = $Cond;

      my $Salinity =
          cond2sal( $cnv_record->{"Temp"}, $cnv_record->{"Press_db"},
                    $cnv_record->{"Cond"}, "T68" );

      ## TODO consider if this is still necessary.
      if ( $useSeabirdTruncation )
      {
        $Salinity = $1 if ( $Salinity =~ /(\d+\.\d\d\d\d)/ );
      }

      $cnv_record->{"Salinity"} = $Salinity;

      #
      # Calculate Sigmas
      #
      my $sigmaTheta = calcSigmaTheta(
                                       $cnv_record->{"Salinity"},
                                       $cnv_record->{"Temp"},
                                       "T68",
                                       $cnv_record->{"Press_db"}
      );
      $cnv_record->{"SigmaTheta"} = $sigmaTheta;

      my $sigmaT =
          Density( $cnv_record->{"Salinity"}, $cnv_record->{"Temp"}, "T68", 0 );
      $cnv_record->{"SigmaT"} = $sigmaT;

      #print "sigmaTheta = $sigmaTheta sigmaT = $sigmaT\n";

      #
      # Process auxilary voltages
      #
      $V0_type = $last_deployment_record->{"V0_type"};
      my $round_V0 = sprintf( "%6.3f", $cnv_record->{"V0_raw"} );
      $coefficients{"$V0_type"} = $V0_coefficients;
      if ( $V0_type ne "NA" )
      {
        my $V0_calc = auxVolt_calc(
                                    $cnv_record->{"V0_raw"},
                                    $V0_type,
                                    $V0_coefficients,
                                    $cnv_record->{"Salinity"},
                                    $cnv_record->{"Temp"},
                                    $cnv_record->{"Press_db"},
                                    "T68"
        );
        $cnv_record->{ $V0_type . "_volts" } = $cnv_record->{"V0_raw"};
        $cnv_record->{$V0_type} = $V0_calc;
      } else
      {
        $cnv_record->{"V0_volts"} = $cnv_record->{"V0_raw"};
      }
      $V1_type = $last_deployment_record->{"V1_type"};

      $coefficients{"$V1_type"} = $V1_coefficients;
      if ( $V1_type ne "NA" )
      {
        my $V1_calc = auxVolt_calc(
                                    $cnv_record->{"V1_raw"},
                                    $V1_type,
                                    $V1_coefficients,
                                    $cnv_record->{"Salinity"},
                                    $cnv_record->{"Temp"},
                                    $cnv_record->{"Press_db"},
                                    "T68"
        );
        $cnv_record->{ $V1_type . "_volts" } = $cnv_record->{"V1_raw"};
        $cnv_record->{$V1_type} = $V1_calc;
      } else
      {
        $cnv_record->{"V1_volts"} = $cnv_record->{"V1_raw"};
      }
      $V2_type = $last_deployment_record->{"V2_type"};

      #print $V2_type."\n";
      $coefficients{"$V2_type"} = $V2_coefficients;
      if ( $V2_type ne "NA" )
      {
        my $V2_calc = auxVolt_calc(
                                    $cnv_record->{"V2_raw"},
                                    $V2_type,
                                    $V2_coefficients,
                                    $cnv_record->{"Salinity"},
                                    $cnv_record->{"Temp"},
                                    $cnv_record->{"Press_db"},
                                    "T68"
        );
        $cnv_record->{ $V2_type . "_volts" } = $cnv_record->{"V2_raw"};
        $cnv_record->{$V2_type} = $V2_calc;
      } else
      {
        $cnv_record->{"V2_volts"} = $cnv_record->{"V2_raw"};
      }
      $V3_type = $last_deployment_record->{"V3_type"};

      #print $V3_type."\n";
      $coefficients{"$V3_type"} = $V3_coefficients;
      if ( $V3_type ne "NA" )
      {
        my $V3_calc = auxVolt_calc(
                                    $cnv_record->{"V3_raw"},
                                    $V3_type,
                                    $V3_coefficients,
                                    $cnv_record->{"Salinity"},
                                    $cnv_record->{"Temp"},
                                    $cnv_record->{"Press_db"},
                                    "T68"
        );
        $cnv_record->{ $V3_type . "_volts" } = $cnv_record->{"V3_raw"};
        $cnv_record->{$V3_type} = $V3_calc;
      } else
      {
        if ( defined $cnv_record->{"V3_raw"} )
        {
          $cnv_record->{"V3_volts"} = $cnv_record->{"V3_raw"};
        }
      }

      if ( $CTD_type eq "SBE19PlusV2" )
      {
        if ( $last_deployment_record->{"V4_type"} )
        {
          $V4_type = $last_deployment_record->{"V4_type"};

          #print $V4_type."\n";
          $coefficients{"$V4_type"} = $V4_coefficients;
          if ( $V4_type ne "NA" )
          {
            my $V4_calc = auxVolt_calc(
                                        $cnv_record->{"V4_raw"},
                                        $V4_type,
                                        $V4_coefficients,
                                        $cnv_record->{"Salinity"},
                                        $cnv_record->{"Temp"},
                                        $cnv_record->{"Press_db"},
                                        "T68"
            );
            $cnv_record->{ $V4_type . "_volts" } = $cnv_record->{"V4_raw"};
            $cnv_record->{$V4_type} = $V4_calc;
          } else
          {
            if ( defined $cnv_record->{"V4_raw"} )
            {
              $cnv_record->{"V4_volts"} = $cnv_record->{"V4_raw"};
            }
          }
        }

        if ( $last_deployment_record->{"V5_type"} )
        {
          $V5_type = $last_deployment_record->{"V5_type"};

          #print $V5_type."\n";
          $coefficients{"$V5_type"} = $V5_coefficients;
          if ( $V5_type ne "NA" )
          {
            my $V5_calc = auxVolt_calc(
                                        $cnv_record->{"V5_raw"},
                                        $V5_type,
                                        $V5_coefficients,
                                        $cnv_record->{"Salinity"},
                                        $cnv_record->{"Temp"},
                                        $cnv_record->{"Press_db"},
                                        "T68"
            );
            $cnv_record->{ $V5_type . "_volts" } = $cnv_record->{"V5_raw"};
            $cnv_record->{$V5_type} = $V5_calc;
          } else
          {
            if ( defined $cnv_record->{"V5_raw"} )
            {
              $cnv_record->{"V5_volts"} = $cnv_record->{"V5_raw"};
            }
          }
        }

        $CTDSerial_type = $last_deployment_record->{"CTDSerial_type"};

        #print $CTDSerial_type."\n";
        $coefficients{"$CTDSerial_type"} = $CTDSerial_coefficients;
        if ( $CTDSerial_type eq "pH" )
        {
          $cnv_record->{"pH_INT"} =
              volts2pH(
                        "INT",
                        $cnv_record->{"Temp"},
                        $cnv_record->{"Salinity"},
                        $cnv_record->{"V_ISFET_INT_raw"},
                        $CTDSerial_coefficients
              );
          $cnv_record->{"pH_EXT"} =
              volts2pH(
                        "EXT",
                        $cnv_record->{"Temp"},
                        $cnv_record->{"Salinity"},
                        $cnv_record->{"V_ISFET_EXT_raw"},
                        $CTDSerial_coefficients
              );
        }

      }

      my $round_O2 = sprintf( "%6.5f", $cnv_record->{"O2"} );
      $cnv_record->{"O2_mg"} = $round_O2 * 1.4291;

      # Per Seabird O2_umol conversion uses SigmaTheta
      $cnv_record->{"O2_umol"} =
          ( 44660 / ( $cnv_record->{"SigmaTheta"} + 1000 ) ) * $round_O2;

     # Derived formula
     #$cnv_record->{"O2_umol"} = (
     #                   $cnv_record->{"O2"} / (
     #                     (
     #                       calcSigma(
     #                         $cnv_record->{"Salinity"}, $cnv_record->{"Temp"},
     #                         $cnv_record->{"Press_db"}, "T68"
     #                       ) / 1000
     #                     ) + 1
     #                   )
     #) * 44.6596;

      #if ( $useSeabirdTruncation )
      #{
      #  my $round_SigmaT = sprintf( "%6.5f", $cnv_record->{"SigmaT"} );
      #
      #    $cnv_record->{"O2_umol"} =
      #        ( 44660 / ( $round_SigmaT + 1000 ) ) * $round_O2;

      $cnv_record->{"O2_sat_mgL"} = Oxysat( $cnv_record->{"Salinity"},
                                $cnv_record->{"Temp"}, "T68", "ml/l" ) * 1.4291;

      $cnv_record->{"O2_sat_ml"} = Oxysat( $cnv_record->{"Salinity"},
                                         $cnv_record->{"Temp"}, "T68", "ml/l" );

    }    # foreach my $cnv_record (@cnv_data)
  }

  #
  # Align Data
  #
  # Correct for the hysteresis of the sensor chain.  The sensors are
  # placed along a water line driven by a pump.  There is a delay between
  # the sample movement through the tube which creates a delay in readings
  # of the same water sample as it moves through the tube.  This can be
  # corrected by shifting columns (sensors) relative to each other.
  #
  # Currently this routine shifts up the Flour and 02 columns based on
  # the alignment # gleaned from a subroutine.  The idea is to shift
  # up the columns and then remove the end rows which correspond to empty
  # Flour and O2 records.
  #
  #          Flour  O2
  #      0    ^      ^
  #      1    ^      ^
  #      .    ^      ^
  #      .    -      -
  #      n    -      -
  #
  # TODO: Consider two things.  Which temp_conv should we use here.  We
  #       use T68 always...above.
  if (    @cnv_data
       && $align_flag == 1
       && defined $last_deployment_record->{"O2_align"}
       && defined $last_deployment_record->{"Fluor_align"} )
  {
    my $align_max = 0;
    if ( $last_deployment_record->{"O2_align"} >
         $last_deployment_record->{"Fluor_align"} )
    {
      $align_max = $last_deployment_record->{"O2_align"};
    } else
    {
      $align_max = $last_deployment_record->{"Fluor_align"};
    }
    if ( $last_deployment_record->{"NO3_align"} > $align_max )
    {
      $align_max = $last_deployment_record->{"NO3_align"};
    }

    for ( my $i = 0 ; $i < ( $#cnv_data - $align_max ) ; $i++ )
    {

      # Shift 02 Volts Column
      if ( exists $cnv_data[ $i ]->{"O2"} )
      {

        $cnv_data[ $i ]->{"O2_volts"} =
            $cnv_data[ $i + $last_deployment_record->{"O2_align"} ]
            ->{"O2_volts"};

        # Recalculate the O2 column from the shifted O2 Volts column
        $cnv_data[ $i ]->{"O2"} =
            auxVolt_calc(
                          $cnv_data[ $i ]->{"O2_volts"},
                          "O2",
                          $coefficients{"O2"},
                          $cnv_data[ $i ]->{"Salinity"},
                          $cnv_data[ $i ]->{"Temp"},
                          $cnv_data[ $i ]->{"Press_db"},
                          "T68"
            );

      }

      my $round_O2 = sprintf( "%6.5f", $cnv_data[ $i ]->{"O2"} );
      $cnv_data[ $i ]->{"O2_mg"} = $round_O2 * 1.4291;
      $cnv_data[ $i ]->{"O2_umol"} =
          ( 44660 / ( $cnv_data[ $i ]->{"SigmaTheta"} + 1000 ) ) * $round_O2;

     #$cnv_data[ $i ]->{"O2_umol"} = (
     #                                 $cnv_data[ $i ]->{"O2"} / (
     #                                        (
     #                                          calcSigma(
     #                                            $cnv_data[ $i ]->{"Salinity"},
     #                                            $cnv_data[ $i ]->{"Temp"},
     #                                            $cnv_data[ $i ]->{"Press_db"},
     #                                            "T68"
     #                                          ) / 1000
     #                                        ) + 1
     #                                 )
     #) * 44.6596;
     #
     #if ( $useSeabirdTruncation )
     #{
     #  my $round_SigmaT =
     #      sprintf( "%6.5f", $cnv_data[ $i ]->{"SigmaT"} );
     #
     #  $cnv_data[ $i ]->{"O2_umol"} =
     #      ( 44660 / ( $round_SigmaT + 1000 ) ) * $round_O2;
     #}else
     #{
     #  $cnv_data[ $i ]->{"O2_umol"} =
     #      ( 44660 / ( $cnv_data[ $i ]->{"SigmaT"} + 1000 ) ) * $round_O2;
     #}

      # Shift Flour Volts column
      if ( exists $cnv_data[ $i ]->{"Fluor"} )
      {

        $cnv_data[ $i ]->{"Fluor_volts"} =
            $cnv_data[ $i + $last_deployment_record->{"Fluor_align"} ]
            ->{"Fluor_volts"};

        # Recalculate the Flour from the shifted Flour Volts column
        $cnv_data[ $i ]->{"Fluor"} =
            auxVolt_calc(
                          $cnv_data[ $i ]->{"Fluor_volts"},
                          "Fluor",
                          $coefficients{"Fluor"},
                          $cnv_data[ $i ]->{"Salinity"},
                          $cnv_data[ $i ]->{"Temp"},
                          $cnv_data[ $i ]->{"Press_db"},
                          "T68"
            );
      }

      # Shift NO3 Volts Column
      if ( exists $cnv_data[ $i ]->{"NO3"} )
      {

        $cnv_data[ $i ]->{"NO3_volts"} =
            $cnv_data[ $i + $last_deployment_record->{"NO3_align"} ]
            ->{"NO3_volts"};

        # Recalculate the NO3 column from the shifted NO3 Volts column
        $cnv_data[ $i ]->{"NO3"} =
            auxVolt_calc(
                          $cnv_data[ $i ]->{"NO3_volts"},
                          "NO3",
                          $coefficients{"NO3"},
                          $cnv_data[ $i ]->{"Salinity"},
                          $cnv_data[ $i ]->{"Temp"},
                          $cnv_data[ $i ]->{"Press_db"},
                          "T68"
            );
      }

    }    # for ( my $i = 0 ; $i < ( $#cnv_data - $align_max )...

    # After the alignment remove the trailing incomplete records
    splice( @cnv_data, $#cnv_data - $align_max + 1, $align_max );
  }

  return ( \@cnv_data, $last_deployment_record, $sample_rate );
}

# END hexfile2cnv_data subroutine

#*************************************************************#
#* Oxysol: Calculate the oxygen solubility for a             *#
#* given salinity, temp: uses the Garcia and Gordon formula  *#
#* using the seabird equation                                *#
#* Input to function: sal, temp, temp covention, units       *#
#* Returns to main: oxygen solubility in specified units     *#
#*************************************************************#
sub Oxysol
{
  my $sal       = shift;
  my $temp      = shift;
  my $temp_conv = shift;
  my $units     = shift;

  # The following equations need temperature to be
  # in ITPS-90 ( unlike most of the Seabird seawater
  # converstion equations! ).  If we are fed the
  # Seabird standard of ITPS-68 we need to convert first.
  # Seabird formulas
  #   T68 = 1.00024*T90
  #   T90 = T68/1.00024
  if ( $temp_conv ne "T90" )
  {
    if ( $temp_conv eq "T68" )
    {
      $temp = $temp / 1.00024;    # in ITPS-90 now
    } else
    {
      die "HexConv.pm::Oxysol(): Called using a unknown "
          . "temperature convention \"$temp_conv\"\n";
    }
  }

#
# This routine uses the equations and constants defined in Seabird documentation;
# http://www.seabird.com/document/
# an64-sbe-43-dissolved-oxygen-sensor-background-information-deployment-recommendations
# Appendix A
#
  my $A0 = 2.00907;
  my $A1 = 3.22014;
  my $A2 = 4.0501;
  my $A3 = 4.94457;
  my $A4 = -0.256847;
  my $A5 = 3.88767;
  my $B0 = -0.00624523;
  my $B1 = -0.00737614;
  my $B2 = -0.010341;
  my $B3 = -0.00817083;
  my $C0 = -0.000000488682;

  # Scale temperature
  # NOTE: perl log() is the natural log (ln)
  my $Ts = log( ( 298.15 - $temp ) / ( 273.15 + $temp ) );

  my $oxysol = exp(
     $A0 +
         ( $A1 * $Ts ) +
         ( $A2 * ( $Ts**2 ) ) +
         ( $A3 * ( $Ts**3 ) ) +
         ( $A4 * ( $Ts**4 ) ) +
         ( $A5 * ( $Ts**5 ) ) +
         (
       $sal *
           ( $B0 + ( $B1 * $Ts ) + ( $B2 * ( $Ts**2 ) ) + ( $B3 * ( $Ts**3 ) ) )
         ) +
         ( $C0 * ( $sal**2 ) )
  );

  if ( $units eq "ml/l" )
  {
    return $oxysol;
  } else
  {
    die
"HexCnv.pm::Oxysol() does not yet accept a units parameter of $units!\n";
  }
}

#*************************************************************#
#* calcSigmaTheta:                                           *#
#*************************************************************#
sub calcSigmaTheta
{
  my $sal       = shift;
  my $temp      = shift;
  my $temp_conv = shift;
  my $press     = shift;

  #
  # The following equations need temperature to be
  # in ITPS-68.  If we are fed the Seabird standard
  # of ITPS-90 we need to convert first.
  # Seabird formulas
  #   T68 = 1.00024*T90
  #   T90 = T68/1.00024
  if ( $temp_conv ne "T68" )
  {
    if ( $temp_conv eq "T90" )
    {
      $temp = $temp * 1.00024;
    } else
    {
      die "HexConv.pm::PotTemp(): Called using a unknown "
          . "temperature convention \"$temp_conv\"\n";
    }
  }

  my $pTemp = PotTemp( $sal, $temp, "T68", $press, 0 );
  my $sigmaTheta = Density( $sal, $pTemp, "T68", 0 );

  return ( $sigmaTheta );
}

#*************************************************************#
#* PotTemp: Calculate the potential temperature              *#
#* Potential temperature if the temperature an element of    *#
#* seaweater would have if raised adiabatically with no      *#
#* change in salinity to reference pressure Pr.              *#
#* Seabird software uses a reference pressure of 0 decibars. *#
#* Given: salinity, temp ( T68 deg C ), pressure p in        *#
#* decibars, and reference pressure pr in decibars.          *#
#* Returns to main: potential temperature in T68 degrees C   *#
#*************************************************************#
sub PotTemp
{
  my $sal       = shift;
  my $temp      = shift;
  my $temp_conv = shift;
  my $press     = shift;
  my $press_ref = shift;

  #
  # The following equations need temperature to be
  # in ITPS-68.  If we are fed the Seabird standard
  # of ITPS-90 we need to convert first.
  # Seabird formulas
  #   T68 = 1.00024*T90
  #   T90 = T68/1.00024
  if ( $temp_conv ne "T68" )
  {
    if ( $temp_conv eq "T90" )
    {
      $temp = $temp * 1.00024;
    } else
    {
      die "HexConv.pm::PotTemp(): Called using a unknown "
          . "temperature convention \"$temp_conv\"\n";
    }
  }

  my $h = $press_ref - $press;
  my $xk = $h * ATG( $sal, $temp, $press );
  $temp += 0.5 * $xk;
  my $q = $xk;
  $press += 0.5 * $h;
  $xk = $h * ATG( $sal, $temp, $press );
  $temp += 0.29289322 * ( $xk - $q );
  $q = 0.58578644 * $xk + 0.121320344 * $q;
  $xk = $h * ATG( $sal, $temp, $press );
  $temp += 1.707106781 * ( $xk - $q );
  $q = 3.414213562 * $xk - 4.121320344 * $q;
  $press += 0.5 * $h;
  $xk = $h * ATG( $sal, $temp, $press );
  $temp = $temp + ( $xk - 2.0 * $q ) / 6.0;

  return ( $temp );

}

#*************************************************************#
#* ATG: helper function for PotTemp() routine.               *#
#* given salinity, temp T68, and pressure return the         *#
#* adiabatic temperature gradient deg C per decibar.         *#
#* Ref: Broyden, H. Deep-Sea Res.,20,401-408                 *#
#* NOTE: Assumes temperatures are in T68!                    *#
#*************************************************************#
sub ATG
{
  my $sal   = shift;
  my $temp  = shift;
  my $press = shift;

  my $ds = $sal - 35.0;
  my $val = (
      (
        ( ( -2.1687e-16 * $temp + 1.8676e-14 ) * $temp - 4.6206e-13 ) * $press +
            (
              ( 2.7759e-12 * $temp - 1.1351e-10 ) *
                  $ds +
                  ( ( -5.4481e-14 * $temp + 8.733e-12 ) * $temp - 6.7795e-10 ) *
                  $temp + 1.8741e-8
            )
      ) * $press +
          ( -4.2393e-8 * $temp + 1.8932e-6 ) * $ds +
          ( ( 6.6228e-10 * $temp - 6.836e-8 ) * $temp + 8.5258e-6 ) * $temp +
          3.5803e-5
  );

  return ( $val );
}

#*************************************************************#
#* Oxysat: Calculate the oxygen saturation for a             *#
#* given salinity, temp: uses seabird equation               *#
#* Input to function: sal, temp, temp covention, units       *#
#* Returns to main: oxygen saturation in specified units     *#
#*************************************************************#
sub Oxysat
{
  my $sal       = shift;
  my $temp      = shift;
  my $temp_conv = shift;
  my $units     = shift;

  ## If using ITPS-68, convert temp
  #if ( $temp_conv eq "T68" )
  #{
  #  $temp *= 1.00024;
  #}

  #
  # The following equations need temperature to be
  # in ITPS-68.  If we are fed the Seabird standard
  # of ITPS-90 we need to convert first.
  # Seabird formulas
  #   T68 = 1.00024*T90
  #   T90 = T68/1.00024
  if ( $temp_conv ne "T68" )
  {
    if ( $temp_conv eq "T90" )
    {
      $temp = $temp * 1.00024;
    } else
    {
      die "HexConv.pm::Oxysat(): Called using a unknown "
          . "temperature convention \"$temp_conv\"\n";
    }
  }

#
# This routine uses the equations and constants defined in Seabird documentation;
#
# define solubility constants
  my $A1 = -173.4292;
  my $A2 = 249.6339;
  my $A3 = 143.3483;
  my $A4 = -21.8492;
  my $B1 = -0.033096;
  my $B2 = 0.014259;
  my $B3 = -0.00170;

  # Scale temperature
  my $Ta = $temp + 273.15;

  # calculate saturation
  my $oxy_sat = exp(
      (
        $A1 + $A2 * ( 100 / $Ta ) + $A3 * log( $Ta / 100 ) + $A4 * ( $Ta / 100 )
      ) + $sal * ( $B1 + $B2 * ( $Ta / 100 ) + $B3 * ( $Ta / 100 )**2 )
  );
  if ( $units eq "ml/l" )
  {
    return $oxy_sat;
  } elsif ( $units eq "mg/l" )
  {
    my $oxy_sat_mg = $oxy_sat * 1.4291;
    return $oxy_sat_mg;
  } elsif ( $units eq "umol/kg" )
  {
    # calculate density (sigma) in g/cm^3
    my $sigmaT = ( calcSigma( $sal, $temp, 0, $temp_conv ) / 1000 ) + 1;
    my $oxy_sat_umol = ( $oxy_sat / $sigmaT ) * 44.6596;
    return $oxy_sat_umol;
  }
}

# END Oxysat subroutine

#*************************************************************#
#* Oxysat_UW: Calculate the oxygen saturation for a given    *#
#* salinity, temp                                            *#
#* Input to function: sal, temp, temp covention, units       *#
#* Returns to main: oxygen saturation in specified units     *#
#*************************************************************#
sub Oxysat_UW
{
  my $sal       = shift;
  my $temp      = shift;
  my $temp_conv = shift;
  my $units     = shift;

  #
  # This routine uses the equations and constants defined in Garcia et al, 1992;
  #
  # define solubility constants
  my $A0 = 5.80871;
  my $A1 = 3.20291;
  my $A2 = 4.17887;
  my $A3 = 5.10006;
  my $A4 = -9.86643e-02;
  my $A5 = 3.80369;
  my $B0 = -7.01577e-03;
  my $B1 = -7.70028e-03;
  my $B2 = -1.13864e-02;
  my $B3 = -9.51519e-03;
  my $C0 = -2.75915e-07;

  # Scale temperature
  #print "About to take log using temp=$temp\n";
  my $Ts = log( ( 298.15 - $temp ) / ( 273.15 + $temp ) );

  # calculate saturation
  my $oxy_sat =
      exp( $A0 +
           $A1 * $Ts +
           $A2 * $Ts**2 +
           $A3 * $Ts**3 +
           $A4 * $Ts**4 +
           $A5 * $Ts**5 +
           $sal * ( $B0 + $B1 * $Ts + $B2 * $Ts**2 + $B3 * $Ts**3 ) +
           $C0 * $sal**2 );
  if ( $units eq "umol/kg" )
  {
    return $oxy_sat;
  } elsif ( $units eq "ml/l" )
  {

    # calculate density (sigma) in g/cm^3
    my $sigmaT = ( calcSigma( $sal, $temp, 0, $temp_conv ) / 1000 ) + 1;
    my $oxy_sat_ml = ( $oxy_sat / 44.6596 ) * $sigmaT;
    return $oxy_sat_ml;
  }
}

# END Oxysat_UW subroutine

#*************************************************************#
#* volts2pH: calculates pH from voltage output of SeaFET     *#
#* Input to function: cell location ("INT" or "EXT", temp,   *#
#*   salinity, voltage, coefficients                         *#
#* Returns to main: pH                                       *#
#*************************************************************#
# TODO: Dependence on T68/T90?
sub volts2pH
{
  my $cell_local      = shift;
  my $temp            = shift;
  my $sal             = shift;
  my $Voltage         = shift;
  my $PH_coefficients = shift;

  my $pH;

### Calibration coefficients...specific to each sensor
  my $K0i = $PH_coefficients->{"PH_K0i"};
  my $K2i = $PH_coefficients->{"PH_K2i"};
  my $K0e = $PH_coefficients->{"PH_K0e"};
  my $K2e = $PH_coefficients->{"PH_K2e"};

### Equation constants
  my $R = 8.314472;      # universal gas constant (J/Kmol)
  my $F = 96485.3415;    # Farraday constant (C/mol)

### Calculated terms (from SeaFET Manual, 1.2.1)
  my $T        = $temp + 273.15;                              #Temp in Kelvin
  my $S_nernst = ( $R * $T * log( 10 ) ) / $F;
  my $Cl_total = ( 0.99889 / 35.453 ) * ( $sal / 1.80655 );
  my $ADH     = ( 0.00000343 * $temp**2 ) + ( 0.00067524 * $temp ) + 0.49172143;
  my $I       = ( 19.924 * $sal ) / ( 1000 - ( 1.005 * $sal ) );
  my $S_total = ( 0.1400 / 96.062 ) * ( $sal / 1.80655 );

  if ( $cell_local eq "INT" )
  {
    $pH = ( $Voltage - $K0i - ( $K2i * $T ) ) / $S_nernst;

  } elsif ( $cell_local eq "EXT" )
  {
    ### Equations
    my $log_gammaHCl =
        ( ( -$ADH * $I**0.5 ) / ( 1 + ( 1.394 * $I**0.5 ) ) ) +
        ( ( 0.08885 - ( 0.000111 * $temp ) ) * $I );
    my $Ks_term1 = 1 - ( 0.001005 * $sal );
    my $Ks_term2 = ( -4276.1 / $T ) + 141.328 - ( 23.093 * log( $T ) );
    my $Ks_term3 =
        ( ( -13856 / $T ) + 324.57 - ( 47.986 * log( $T ) ) ) * $I**0.5;
    my $Ks_term4 = ( ( 35474 / $T ) - 771.54 + ( 114.723 * log( $T ) ) ) * $I;
    my $Ks_term5 = ( 2698 / $T ) * $I**1.5;
    my $Ks_term6 = ( 1776 / $T ) * $I**2;
    my $Ks       = $Ks_term1 *
        exp( $Ks_term2 + $Ks_term3 + $Ks_term4 - $Ks_term5 + $Ks_term6 );

    ### Calculate pH
    $pH =
        ( ( $Voltage - $K0e - ( $K2e * $T ) ) / $S_nernst ) +
        log10( $Cl_total ) +
        ( 2 * $log_gammaHCl ) -
        log10( 1 + ( $S_total / $Ks ) );
  }

  return $pH;

}

# END volts2pH subroutine

#*************************************************************#
#* seabird_truncRound: truncates and rounds number           *#
#* Input to function: variable                               *#
#* Returns to main: variable                                 *#
#*************************************************************#
sub seabird_truncRound
{
  my $truncate_value = shift;

  $truncate_value *= 256;
  $truncate_value = sprintf( "%7.0f", $truncate_value );
  $truncate_value /= 256;
  $truncate_value = sprintf( "%6.3f", $truncate_value );
  return ( $truncate_value );
}

# END seabird_truncRound subroutine

1;
