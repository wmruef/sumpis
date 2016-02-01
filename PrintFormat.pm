#!/usr/bin/perl

package PrintFormat;

use strict;
use Time::Local;
use Data::Dumper;
use lib "/home/orca/bin/sumpis";
use dataTasks;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA = qw(Exporter);
@EXPORT =
    qw(data2calfile print19Plus_cnv print19Plus_custom print19_cnv print_default print_discreteO2 print_discreteO2_v2 print_discreteO2_v3 print_calibrationsO2 print_discreteChl print_discreteNut print_discreteNO3 print_discreteO2_basic print_discrete print_discreteV2 );
@EXPORT_OK = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* data2calfile: Writes cnv_data out to a CAST.CAL file      *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub data2calfile
{
  my $data      = shift;
  my $file_cast = shift;

  my $filename = $file_cast . ".HTA";

  open FILE, ">$filename" or die "Can't open $filename!!!!$!\n";
  my @key_names = keys( %{ $data->[ 0 ] } );
  print FILE join( "\t", @key_names ) . "\n";
  foreach my $record ( @{$data} )
  {
    foreach my $key_name ( @key_names )
    {
      print FILE $record->{$key_name} . "\t";
    }
    print FILE "\n";
  }

  #print FILE Dumper($data);
  close FILE;
  return;
}

# END data2calfile subroutine

#*************************************************************#
#* print19Plus_cnv: Writes cnv_data out to a CAST.HTA file,  *#
#* with columns identical to the CASTderive.CNV file,        *#
#* with no header                                            *#
#* Input to function: data structure, file cast              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print19Plus_cnv
{
  my $data      = shift;
  my $file_cast = shift;

  my $file_out = $file_cast . ".HTA";
  open FILE_OUT, ">$file_out" or die "Can't open $file_out!!!!!\n";
  print FILE_OUT "*END*\n";
  my $scan      = 1;
  my @key_names = keys( %{ $data->[ 0 ] } );
  foreach my $record ( @{$data} )
  {
    print FILE_OUT "\t";

    print FILE_OUT $scan . "\t";

    my $round_press_db = sprintf( "%6.3f", $record->{"Press_db"} );
    print FILE_OUT $round_press_db . "\t";

    my $round_press_psi = sprintf( "%6.3f", $record->{"Press_psi"} );
    print FILE_OUT $round_press_psi . "\t";

    my $round_Temp_freq_seabird = sprintf( "%7.3f", $record->{"Temp_raw"} );
    print FILE_OUT $round_Temp_freq_seabird . "\t";

    my $round_Cond_freq_seabird = sprintf( "%7.3f", $record->{"Cond_raw"} );
    print FILE_OUT $round_Cond_freq_seabird . "\t";

    # We now assume that $record->{"Temp"} is in T68 so we need to
    # convert before printing in the T90 standard.
    # Seabird formulas
    #   T68 = 1.00024*T90
    #   T90 = T68/1.00024
    #
    my $round_Temp_seabird = sprintf( "%6.4f", $record->{"Temp"} / 1.00024 );
    print FILE_OUT $round_Temp_seabird . "\t";

    my $round_Cond_seabird = sprintf( "%7.6f", $record->{"Cond"} );
    print FILE_OUT $round_Cond_seabird . "\t";

    my $round_V0_raw = sprintf( "%5.4f", $record->{"V0_raw"} );
    print FILE_OUT $round_V0_raw . "\t";

    my $round_V1_raw = sprintf( "%5.4f", $record->{"V1_raw"} );
    print FILE_OUT $round_V1_raw . "\t";

    my $round_V2_raw = sprintf( "%5.4f", $record->{"V2_raw"} );
    print FILE_OUT $round_V2_raw . "\t";

    my $round_V3_raw = sprintf( "%5.4f", $record->{"V3_raw"} );
    print FILE_OUT $round_V3_raw . "\t";

    my $round_O2_volts = sprintf( "%5.4f", $record->{"O2_volts"} );
    print FILE_OUT $round_O2_volts . "\t";

    my $round_Fluor = sprintf( "%6.4f", $record->{"Fluor"} );
    print FILE_OUT $round_Fluor . "\t";

    my $round_Depth_seabird = sprintf( "%6.3f", $record->{"Depth"} );
    print FILE_OUT $round_Depth_seabird . "\t";

    my $round_Salinity_seabird = sprintf( "%6.4f", $record->{"Salinity"} );
    print FILE_OUT $round_Salinity_seabird . "\t";

    my $round_SigmaT_seabird = sprintf( "%6.4f", $record->{"SigmaT"} );
    print FILE_OUT $round_SigmaT_seabird . "\t";

    my $round_O2 = sprintf( "%7.5f", $record->{"O2"} );
    print FILE_OUT $round_O2 . "\t";

    my $round_O2_mg = sprintf( "%7.5f", $record->{"O2_mg"} );
    print FILE_OUT $round_O2_mg . "\t";

    my $round_O2_umol_seabird = sprintf( "%6.3f", $record->{"O2_umol"} );
    print FILE_OUT $round_O2_umol_seabird . "\t";

    my $round_O2_sat_ml = sprintf( "%7.5f", $record->{"O2_sat_ml"} );
    print FILE_OUT $round_O2_sat_ml . "\t";

    my $round_O2_sat_mgL = sprintf( "%7.5f", $record->{"O2_sat_mgL"} );
    print FILE_OUT $round_O2_sat_mgL . "\t";

    if ( exists $record->{"NO3"} )
    {
      my $round_NO3 = sprintf( "%8.6f", $record->{"NO3"} );
      print FILE_OUT $round_NO3 . "\t";
    }

    if ( exists $record->{"PAR"} )
    {
      my $round_PAR = sprintf( "%8.6f", $record->{"PAR"} );
      print FILE_OUT $round_PAR . "\t";
    }

    print FILE_OUT "0.0000e+00\n";
    $scan += 1;
  }

  close FILE_OUT;
  return;
}

# END print19Plus_cnv subroutine

#*************************************************************#
#* print19Plus_custom: Writes data out to a CAST.DGC file.   *#
#* Header includes ds from hex file, column headers.         *#
#* Input to function: data structure, file cast              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print19Plus_custom
{
  my $data      = shift;
  my $file_cast = shift;

  my $file_hex = $file_cast . ".HEX";

  #print "my printing hex file is:::::$file_hex\n";
  my $file_out = $file_cast . ".DGC";

  open FILE_HEX, "<$file_hex" or die "Cannot open $file_hex!!!!!\n";

  open FILE_OUT, ">$file_out" or die "Cannot open $file_out!!!!!\n";

  # Read hex file header line by line
  while ( <FILE_HEX> )
  {
    last if ( /S>DC/ );

    #if ( /(\*.*)/) {
    if ( /(\S.*)/ )
    {
      print FILE_OUT $1;
      print FILE_OUT "\n";
    }
  }
  close FILE_HEX;
  print FILE_OUT "* column 1: Scan Number\n";
  print FILE_OUT "* column 2: Pressure, db\n";
  print FILE_OUT "* column 3: Conductivity, S/m\n";
  print FILE_OUT "* column 4: Temperature, degrees C\n";
  print FILE_OUT "* column 5: Voltage channel 0, volts\n";
  print FILE_OUT "* column 6: Voltage channel 1, volts\n";
  print FILE_OUT "* column 7: Voltage channel 2, volts\n";
  print FILE_OUT "* column 8: Voltage channel 3, volts\n";
  print FILE_OUT "* column 9: Oxygen voltage, volts\n";
  print FILE_OUT "* column 10: Fluorometer, mg/m^3\n";
  print FILE_OUT "* column 11: NO3\n";
  print FILE_OUT "* column 12: Depth, m\n";
  print FILE_OUT "* column 13: Salinity, psu\n";
  print FILE_OUT "* column 14: Sigma-T, kg/m^3\n";
  print FILE_OUT "* column 15: Oxygen, mg/L\n";
  print FILE_OUT "* column 16: Oxygen, umol/kg\n";
  print FILE_OUT "* column 17: Oxygen saturation, mg/L\n";
  print FILE_OUT "* column 18: flag\n";
  print FILE_OUT "*END*\n";
  my $scan      = 1;
  my $bytes     = 19;
  my @key_names = keys( %{ $data->[ 0 ] } );

  #print FILE_OUT join( "\t", @key_names ) . "\n";
  foreach my $record ( @{$data} )
  {
    print FILE_OUT "\t";
    print FILE_OUT $scan . "\t";
    my $round_press_db = sprintf( "%6.3f", $record->{"Press_db"} );
    print FILE_OUT $round_press_db . "\t";

    #print FILE_OUT $record->{"Press_db"} . "\t";
    my $round_cond = sprintf( "%7.6f", $record->{"Cond"} );
    print FILE_OUT $round_cond . "\t";

    #print FILE_OUT $record->{"Cond"} . "\t";
    # We now assume that $record->{"Temp"} is in T68 so we need to
    # convert before printing in the T90 standard.
    # Seabird formulas
    #   T68 = 1.00024*T90
    #   T90 = T68/1.00024
    #
    my $round_temp = sprintf( "%6.4f", $record->{"Temp"} / 1.00024 );
    print FILE_OUT $round_temp . "\t";

    #print FILE_OUT $record->{"Temp"} . "\t";
    my $round_v0_raw = sprintf( "%5.4f", $record->{"V0_raw"} );
    print FILE_OUT $round_v0_raw . "\t";

    #print FILE_OUT $record->{"V0_raw"} . "\t";
    my $round_v1_raw = sprintf( "%5.4f", $record->{"V1_raw"} );
    print FILE_OUT $round_v1_raw . "\t";

    #print FILE_OUT $record->{"V1_raw"} . "\t";
    my $round_v2_raw = sprintf( "%5.4f", $record->{"V2_raw"} );
    print FILE_OUT $round_v2_raw . "\t";

    #print FILE_OUT $record->{"V2_raw"} . "\t";
    if ( $record->{"V3_raw"} )
    {
      my $round_v3_raw = sprintf( "%5.4f", $record->{"V3_raw"} );
      print FILE_OUT $round_v3_raw . "\t";

      #print FILE_OUT $record->{"V3_raw"} . "\t";
    } else
    {
      print FILE_OUT "0.0000\t";
    }
    my $round_O2_volts = sprintf( "%5.4f", $record->{"O2_volts"} );
    print FILE_OUT $round_O2_volts . "\t";

    #print FILE_OUT $record->{"O2_volts"} . "\t";
    if ( $record->{"Fluor"} )
    {
      my $round_fluor = sprintf( "%5.4f", $record->{"Fluor"} );
      print FILE_OUT $round_fluor . "\t";

      #print FILE_OUT $record->{"Fluor"} . "\t";
    } else
    {
      print FILE_OUT "0.0000\t";
    }
    if ( $record->{"NO3"} )
    {
      my $round_NO3 = sprintf( "%5.4f", $record->{"NO3"} );
      print FILE_OUT $round_NO3 . "\t";

      #print FILE_OUT $record->{"NO3"} . "\t";
    } else
    {
      print FILE_OUT $bytes . "\t";
    }
    my $round_depth = sprintf( "%5.3f", $record->{"Depth"} );
    print FILE_OUT $round_depth . "\t";

    #print FILE_OUT $record->{"Depth"} . "\t";
    my $round_sal = sprintf( "%6.4f", $record->{"Salinity"} );
    print FILE_OUT $round_sal . "\t";

    #print FILE_OUT $record->{"Salinity"} . "\t";
    my $round_sigma = sprintf( "%6.4f", $record->{"SigmaT"} );
    print FILE_OUT $round_sigma . "\t";

    #print FILE_OUT $record->{"SigmaT_seabird"} . "\t";
    my $round_O2_mg = sprintf( "%6.5f", $record->{"O2_mg"} );
    print FILE_OUT $round_O2_mg . "\t";

    #print FILE_OUT $record->{"O2_mg"} . "\t";
    my $round_O2_umol = sprintf( "%5.3f", $record->{"O2_umol"} );
    print FILE_OUT $round_O2_umol . "\t";

    #print FILE_OUT $record->{"O2_umol_seabird"} . "\t";
    my $round_O2_sat = sprintf( "%6.5f", $record->{"O2_sat_mgL"} );
    print FILE_OUT $round_O2_sat . "\t";

    #print FILE_OUT $record->{"O2_sat_mgL"} . "\t";
    print FILE_OUT "0.0000e+00\n";
    $scan  += 1;
    $bytes += 19;
  }

  close FILE_OUT;
  return;
}

# END print19Plus_custom subroutine

#*************************************************************#
#* print19_cnv: Writes cnv_data out to a CAST.HTA file,      *#
#* with columns identical to the CASTderive.CNV file,        *#
#* with no header                                            *#
#* Input to function: data structure, file cast              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print19_cnv
{
  my $data      = shift;
  my $file_cast = shift;

  my $file_out = $file_cast . ".HTA";
  open FILE_OUT, ">$file_out" or die "Can't open $file_out!!!!!\n";
  print FILE_OUT "*END*\n";
  my $scan      = 1;
  my @key_names = keys( %{ $data->[ 0 ] } );

  #print FILE_OUT join( "\t", @key_names ) . "\n";
  foreach my $record ( @{$data} )
  {
    print FILE_OUT "\t";

    print FILE_OUT $scan . "\t";

    #print FILE_OUT $record->{"Data_scan_index"} . "\t";
    #print FILE_OUT $record->{"Ref_scan_index"} . "\t";
    #print FILE_OUT $record->{"IsRef"} . "\t";
    #print FILE_OUT $record->{"Ref_High_orig"} . "\t";
    #print FILE_OUT $record->{"Ref_High_int"} . "\t";
    #print FILE_OUT $record->{"Ref_High_final"} . "\t";
    #print FILE_OUT $record->{"Ref_Low_orig"} . "\t";
    #print FILE_OUT $record->{"Ref_Low_int"} . "\t";
    #print FILE_OUT $record->{"Ref_Low_final"} . "\t";
    #print FILE_OUT $record->{"freq_cor_a"} . "\t";
    #print FILE_OUT $record->{"freq_cor_b"} . "\t";
    #print FILE_OUT $record->{"freq1I"} . "\t";
    #print FILE_OUT $record->{"freq4I"} . "\t";
    #print FILE_OUT $record->{"temp_freq1"} . "\t";
    #print FILE_OUT $record->{"temp_freq4"} . "\t";
    #print FILE_OUT $record->{"cond_freq1"} . "\t";
    #print FILE_OUT $record->{"cond_freq4"} . "\t";
    #print FILE_OUT $record->{"Raw_Temp_freq"} . "\t";
    #print FILE_OUT $record->{"Raw_Cond_freq"} . "\t";
    #print FILE_OUT $record->{"Temp_freq"} . "\t";
    #print FILE_OUT $record->{"Temp_freq_seabird"} . "\t";
    #print FILE_OUT $record->{"Cond_freq"} . "\t";
    #print FILE_OUT $record->{"Cond_freq_seabird"} . "\n";

    my $round_press_db = sprintf( "%6.3f", $record->{"Press_db"} );
    print FILE_OUT $round_press_db . "\t";
    #####print FILE_OUT $record->{"Press_db"} . "\t";

    my $round_press_psi = sprintf( "%6.3f", $record->{"Press_psi"} );
    print FILE_OUT $round_press_psi . "\t";
    #####print FILE_OUT $record->{"Press_psi"} . "\t";

    my $round_Temp_freq_seabird = sprintf( "%7.3f", $record->{"Temp_freq"} );
    print FILE_OUT $round_Temp_freq_seabird . "\t";
    #####print FILE_OUT $record->{"Temp_freq_seabird"} . "\t";

    my $round_Cond_freq_seabird = sprintf( "%7.3f", $record->{"Cond_freq"} );
    print FILE_OUT $round_Cond_freq_seabird . "\t";

    #
    # We now assume that $record->{"Temp"} is in T68 so we need to
    # convert before printing in the T90 standard.
    # Seabird formulas
    #   T68 = 1.00024*T90
    #   T90 = T68/1.00024
    #
    my $round_Temp_seabird = sprintf( "%6.4f", $record->{"Temp"} / 1.00024 );
    print FILE_OUT $round_Temp_seabird . "\t";
    #####print FILE_OUT $record->{"Temp_seabird"} . "\t";

    my $round_Cond_seabird = sprintf( "%7.6f", $record->{"Cond"} );
    print FILE_OUT $round_Cond_seabird . "\t";
    #####print FILE_OUT $record->{"Cond_seabird"} . "\t";

    my $round_V0_raw = sprintf( "%5.4f", $record->{"V0_raw"} );
    print FILE_OUT $round_V0_raw . "\t";
    #####print FILE_OUT $record->{"V0_raw"} . "\t";

    my $round_V1_raw = sprintf( "%5.4f", $record->{"V1_raw"} );
    print FILE_OUT $round_V1_raw . "\t";
    #####print FILE_OUT $record->{"V1_raw"} . "\t";

    my $round_V2_raw = sprintf( "%5.4f", $record->{"V2_raw"} );
    print FILE_OUT $round_V2_raw . "\t";
    #####print FILE_OUT $record->{"V2_raw"} . "\t";

    my $round_V3_raw = sprintf( "%5.4f", $record->{"V3_raw"} );
    print FILE_OUT $round_V3_raw . "\t";
    #####print FILE_OUT $record->{"V3_raw"} . "\t";

    my $round_O2_volts = sprintf( "%5.4f", $record->{"O2_volts"} );
    print FILE_OUT $round_O2_volts . "\t";
    #####print FILE_OUT $record->{"O2_volts"} . "\t";

    my $round_Fluor = sprintf( "%6.4f", $record->{"Fluor"} );
    print FILE_OUT $round_Fluor . "\t";
    #####print FILE_OUT $record->{"Fluor"} . "\t";

    my $round_Depth_seabird = sprintf( "%6.3f", $record->{"Depth"} );
    print FILE_OUT $round_Depth_seabird . "\t";
    #####print FILE_OUT $record->{"Depth_seabird"} . "\t";

    my $round_Salinity_seabird = sprintf( "%6.4f", $record->{"Salinity"} );
    print FILE_OUT $round_Salinity_seabird . "\t";
    #####print FILE_OUT $record->{"Salinity_seabird"} . "\t";

    my $round_SigmaT_seabird = sprintf( "%6.4f", $record->{"SigmaT"} );
    print FILE_OUT $round_SigmaT_seabird . "\t";
    #####print FILE_OUT $record->{"SigmaT_seabird"} . "\t";

    my $round_O2 = sprintf( "%7.5f", $record->{"O2"} );
    print FILE_OUT $round_O2 . "\t";
    #####print FILE_OUT $record->{"O2"} . "\t";

    my $round_O2_mg = sprintf( "%7.5f", $record->{"O2_mg"} );
    print FILE_OUT $round_O2_mg . "\t";
    #####print FILE_OUT $record->{"O2_mg"} . "\t";

    my $round_O2_umol_seabird = sprintf( "%6.3f", $record->{"O2_umol"} );
    print FILE_OUT $round_O2_umol_seabird . "\t";
    #####print FILE_OUT $record->{"O2_umol_seabird"} . "\t";

    my $round_O2_sat_ml = sprintf( "%7.5f", $record->{"O2_sat_ml"} );
    print FILE_OUT $round_O2_sat_ml . "\t";
    #####print FILE_OUT $record->{"O2_sat_ml"} . "\t";

    my $round_O2_sat_mgL = sprintf( "%7.5f", $record->{"O2_sat_mgL"} );
    print FILE_OUT $round_O2_sat_mgL . "\t";
    #####print FILE_OUT $record->{"O2_sat_mgL"} . "\t";

    print FILE_OUT "0.0000e+00\n";
    $scan += 1;
  }

  close FILE_OUT;
  return;
}

# END print19_cnv subroutine

#*************************************************************#
#* print_default: Writes data out to a CAST.DGC file in      *#
#* default column order.                                     *#
#* Header includes ds from hex file, column headers.         *#
#* Input to function: data structure, file cast              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_default
{
  my $data      = shift;
  my $file_cast = shift;

  my $file_hex = $file_cast . ".HEX";
  my $file_out = $file_cast . ".DGC";

  open FILE_HEX, "<$file_hex" or die "Cannot open $file_hex!!!!!\n";
  open FILE_OUT, ">$file_out" or die "Cannot open $file_out!!!!!\n";

  # Read hex file header line by line
  while ( <FILE_HEX> )
  {
    last if ( /^[A-F0-9]+\s*$/ );
    if ( /(\S.*)/ )
    {
      print FILE_OUT $1;
      print FILE_OUT "\n";
    }
  }
  close FILE_HEX;
  print FILE_OUT
"\n*** NOTE: Values of -555 are entered when no data is available from the sensor. ***\n";
  print FILE_OUT "\n* column 1: Scan Number\n";
  print FILE_OUT "* column 2: Pressure, db\n";
  print FILE_OUT "* column 3: Conductivity, S/m\n";
  print FILE_OUT "* column 4: Temperature, degrees C\n";
  print FILE_OUT "* column 5: Voltage channel 0, volts\n";
  print FILE_OUT "* column 6: Voltage channel 1, volts\n";
  print FILE_OUT "* column 7: Voltage channel 2, volts\n";
  print FILE_OUT "* column 8: Voltage channel 3, volts\n";
  print FILE_OUT "* column 9: voltage channel 4, volts\n";
  print FILE_OUT "* column 10: Voltage channel 5, volts\n";
  print FILE_OUT "* column 11: Oxygen voltage, volts\n";
  print FILE_OUT "* column 12: Fluorometer, mg/m^3\n";
  print FILE_OUT "* column 13: NO3, umol\n";
  print FILE_OUT "* column 14: Depth, m\n";
  print FILE_OUT "* column 15: Salinity, psu\n";
  print FILE_OUT "* column 16: Sigma-T, kg/m^3\n";
  print FILE_OUT "* column 17: Oxygen, mg/L\n";
  print FILE_OUT "* column 18: Oxygen, umol/kg\n";
  print FILE_OUT "* column 19: Oxygen saturation, mg/L\n";
  print FILE_OUT "* column 20: PAR, uEinsteins/m^2-sec\n";
  print FILE_OUT "* column 21: Turbidity, NTU\n";

  if ( exists $data->[ 0 ]->{"pH_INT"} )
  {
    print "PH installed!!!\n";
    print FILE_OUT "* column 22: pH, internal voltage\n";
    print FILE_OUT "* column 23: pH, external voltage\n";
    print FILE_OUT "* column 24: pH, internal\n";
    print FILE_OUT "* column 25: pH, external\n";
  }

  print FILE_OUT "*END HEADER*\n\n";
  my $scan = 1;
  foreach my $record ( @{$data} )
  {
    print FILE_OUT "\t";

    print FILE_OUT $scan . "\t";

    if ( exists $record->{"Press_db"} )
    {
      my $round_press_db = sprintf( "%6.3f", $record->{"Press_db"} );
      print FILE_OUT $round_press_db . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"Cond"} )
    {
      my $round_cond = sprintf( "%7.6f", $record->{"Cond"} );
      print FILE_OUT $round_cond . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"Temp"} )
    {
      # We now assume that $record->{"Temp"} is in T68 so we need to
      # convert before printing in the T90 standard.
      # Seabird formulas
      #   T68 = 1.00024*T90
      #   T90 = T68/1.00024
      #
      my $round_temp = sprintf( "%6.4f", $record->{"Temp"} / 1.00024 );
      print FILE_OUT $round_temp . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"V0_raw"} )
    {
      my $round_v0_raw = sprintf( "%5.4f", $record->{"V0_raw"} );
      print FILE_OUT $round_v0_raw . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"V1_raw"} )
    {
      my $round_v1_raw = sprintf( "%5.4f", $record->{"V1_raw"} );
      print FILE_OUT $round_v1_raw . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"V2_raw"} )
    {
      my $round_v2_raw = sprintf( "%5.4f", $record->{"V2_raw"} );
      print FILE_OUT $round_v2_raw . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"V3_raw"} )
    {
      my $round_v3_raw = sprintf( "%5.4f", $record->{"V3_raw"} );
      print FILE_OUT $round_v3_raw . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"V4_raw"} )
    {
      my $round_v3_raw = sprintf( "%5.4f", $record->{"V3_raw"} );
      print FILE_OUT $round_v3_raw . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"V5_raw"} )
    {
      my $round_v3_raw = sprintf( "%5.4f", $record->{"V3_raw"} );
      print FILE_OUT $round_v3_raw . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"O2_volts"} )
    {
      my $round_O2_volts = sprintf( "%5.4f", $record->{"O2_volts"} );
      print FILE_OUT $round_O2_volts . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"Fluor"} )
    {
      my $round_fluor = sprintf( "%5.4f", $record->{"Fluor"} );
      print FILE_OUT $round_fluor . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"NO3"} )
    {
      my $round_NO3 = sprintf( "%5.4f", $record->{"NO3"} );
      print FILE_OUT $round_NO3 . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"Depth"} )
    {
      my $round_depth = sprintf( "%5.3f", $record->{"Depth"} );
      print FILE_OUT $round_depth . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"Salinity"} )
    {
      my $round_sal = sprintf( "%6.4f", $record->{"Salinity"} );
      print FILE_OUT $round_sal . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"SigmaT"} )
    {
      my $round_sigma = sprintf( "%6.4f", $record->{"SigmaT"} );
      print FILE_OUT $round_sigma . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"O2_mg"} )
    {
      my $round_O2_mg = sprintf( "%6.5f", $record->{"O2_mg"} );
      print FILE_OUT $round_O2_mg . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"O2_umol"} )
    {
      my $round_O2_umol = sprintf( "%5.3f", $record->{"O2_umol"} );
      print FILE_OUT $round_O2_umol . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"O2_sat_mgL"} )
    {
      my $round_O2_sat = sprintf( "%6.5f", $record->{"O2_sat_mgL"} );
      print FILE_OUT $round_O2_sat . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"PAR"} )
    {
      my $round_par = sprintf( "%6.5f", $record->{"PAR"} );
      print FILE_OUT $round_par . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"Turb"} )
    {
      my $round_turb = sprintf( "%5.4f", $record->{"Turb"} );
      print FILE_OUT $round_turb . "\t";
    } else
    {
      print FILE_OUT "-555\t";
    }

    if ( exists $record->{"pH_INT"} )
    {
      my $round_pH_IntVolt = sprintf( "%7.6f", $record->{"V_ISFET_INT_raw"} );
      print FILE_OUT $round_pH_IntVolt . "\t";
      my $round_pH_ExtVolt = sprintf( "%7.6f", $record->{"V_ISFET_EXT_raw"} );
      print FILE_OUT $round_pH_ExtVolt . "\t";
      my $round_pH_Int = sprintf( "%7.6f", $record->{"pH_INT"} );
      print FILE_OUT $round_pH_Int . "\t";
      my $round_pH_Ext = sprintf( "%7.6f", $record->{"pH_EXT"} );
      print FILE_OUT $round_pH_Ext . "\t";
    }

    print FILE_OUT "\n";
    $scan += 1;
  }

  close FILE_OUT;
  return;
}

# END print_default subroutine

#*************************************************************#
#* print_discreteO2: Writes discrete Oxygen data out to a    *#
#* file                                                      *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteO2
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  print FILE_OUT"\n*** Top of file: Oxygen Winkler Values ***\n";
  print FILE_OUT "\n* column 1: Date\n";
  print FILE_OUT "* column 2: CTD file\n";
  print FILE_OUT "* column 3: Depth\n";
  print FILE_OUT "* column 4: Oxygen Concentration, in ml/L\n";
  print FILE_OUT "* column 5: Intentionally left blank\n";
  print FILE_OUT "* column 6: Normality of Standard\n";
  print FILE_OUT "* column 7: Reagent Blank\n";
  print FILE_OUT "* column 8: Volume of Titrant added to Standard, ml\n";
  print FILE_OUT "* column 9: Volume of Standard (volume of pippette), ml\n";
  print FILE_OUT "* column 10: Volume of Titrant added to Sample, ml\n";
  print FILE_OUT "* column 11: Bottle Number\n";
  print FILE_OUT "* column 12: Bottle Volume, ml\n";
  print FILE_OUT "\n*****\n";
  print FILE_OUT "\n*** Bottom of file: CTD and Winkler calibration summary\n";
  print FILE_OUT "\n* column 1: Date\n";
  print FILE_OUT "* column 2: CTD file\n";
  print FILE_OUT "* column 3: Winkler Depth\n";
  print FILE_OUT "* column 4: CTD Depth\n";
  print FILE_OUT "* column 5: CTD Oxygen, mL/L\n";
  print FILE_OUT "* column 6: Winkler Oxygen, mL/L\n";
  print FILE_OUT "* column 7: Winkler Std Dev\n";
  print FILE_OUT "* column 8: Winkler % Std Dev\n";
  print FILE_OUT "* column 9: Percent Diff, %\n";
  print FILE_OUT "* column 10: Oxygen Model\n";
  print FILE_OUT "* column 11: Oxygen SN\n";
  print FILE_OUT "\n*END HEADER*\n\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $sample_record_index = $#{ $discrete_record->{"samples"} };
    my $i                   = 0;
    for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
    {
      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"depth"} . "\t";
      my $round_O2 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"O2_ml"} );
      print FILE_OUT $round_O2 . "\t";
      ##print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"O2_ml"}."\t";
      print FILE_OUT "\t";
      print FILE_OUT $discrete_record->{"stnd_nrml"} . "\t";
      print FILE_OUT $discrete_record->{"blnk"} . "\t";
      print FILE_OUT $discrete_record->{"stnd_ml"} . "\t";
      print FILE_OUT $discrete_record->{"KIO3_ml"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"samp_ml"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"bottle"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"btlVol"} . "\t";
      print FILE_OUT "\n";
    }
  }

  print FILE_OUT "\n\n*****\n\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Winkler_depth"} . "\t";
      print "winkler depth: "
          . $discrete_record->{"Cals"}[ $i ]->{"Winkler_depth"} . "\t";
      my $round_CTD_depth =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
      print FILE_OUT $round_CTD_depth . "\t";
      my $round_CTD_Oxy_mL =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Oxy_mL"} );
      print FILE_OUT $round_CTD_Oxy_mL . "\t";
      my $round_Winkler_Oxy_mL = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Winkler_Oxy_mL"} );
      print FILE_OUT $round_Winkler_Oxy_mL . "\t";
      my $round_Winkler_stdDev = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Winkler_stdDev"} );
      print FILE_OUT $round_Winkler_stdDev . "\t";
      my $round_Winkler_percentStdDev =
          sprintf( "%8.3f",
                   $discrete_record->{"Cals"}[ $i ]->{"Winkler_percentStdDev"}
          );
      print FILE_OUT $round_Winkler_percentStdDev . "\t";
      my $round_percentDiff =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"percentDiff"} );
      print FILE_OUT $round_percentDiff . "\t";
      print FILE_OUT $discrete_record->{"O2_model"} . "\t";
      print FILE_OUT $discrete_record->{"O2_SN"} . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteO2

#*************************************************************#
#* print_discreteO2_v2: Writes discrete Oxygen data out to a    *#
#* file                                                      *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteO2_v2
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  print FILE_OUT"\n*** Top of file: Oxygen Winkler Values ***\n";
  print FILE_OUT "\n* column 1: Date\n";
  print FILE_OUT "* column 2: CTD file\n";
  print FILE_OUT "* column 3: Depth\n";
  print FILE_OUT "* column 4: Oxygen Concentration, in ml/L\n";
  print FILE_OUT "* column 6: Normality of Standard\n";
  print FILE_OUT "* column 7: Reagent Blank\n";
  print FILE_OUT "* column 8: Volume of Titrant added to Standard, ml\n";
  print FILE_OUT "* column 9: Volume of Standard (volume of pippette), ml\n";
  print FILE_OUT "* column 10: Volume of Titrant added to Sample, ml\n";
  print FILE_OUT "* column 11: Bottle Number\n";
  print FILE_OUT "* column 12: Bottle Volume, ml\n";
  print FILE_OUT "\n*****\n";
  print FILE_OUT "\n*** Bottom of file: CTD and Winkler calibration summary\n";
  print FILE_OUT "\n* column 1: Date\n";
  print FILE_OUT "* column 2: CTD file\n";
  print FILE_OUT "* column 3: Winkler Depth\n";
  print FILE_OUT "* column 4: CTD Depth\n";
  print FILE_OUT "* column 5: CTD Oxygen, mL/L\n";
  print FILE_OUT "* column 6: Winkler Oxygen, mL/L\n";
  print FILE_OUT "* column 7: Winkler Std Dev\n";
  print FILE_OUT "* column 8: Winkler % Std Dev\n";
  print FILE_OUT "* column 9: Percent Diff, %\n";
  print FILE_OUT "* column 10: Oxygen Model\n";
  print FILE_OUT "* column 11: Oxygen SN\n";
  print FILE_OUT "\n*END HEADER*\n\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    #print "full discrete record: ".Dumper($discrete_record)."\n";
    print FILE_OUT "\n";
    my $sample_record_index = $#{ $discrete_record->{"samples"} };
    my $i                   = 0;
    for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
    {
      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"depth"} . "\t";
      my $round_O2 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"O2_ml"} );
      print FILE_OUT $round_O2 . "\t";
      print FILE_OUT $discrete_record->{"stnd_nrml"} . "\t";
      print FILE_OUT $discrete_record->{"blnk"} . "\t";
      print FILE_OUT $discrete_record->{"stnd_ml"} . "\t";
      print FILE_OUT $discrete_record->{"KIO3_ml"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"samp_ml"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"bottle"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"btlVol"} . "\t";
      print FILE_OUT "\n";
    }
  }

  print FILE_OUT
"Date\tCTD file\tWinkler Depth\tCTD depth\tCTD Oxygen\tWinkler Oxygen\tWinkler Std Dev\t Winkler % Std Dev\tPercent Diff %\tOxygen Model\tOxygen SN\t";

  # print headers
  foreach my $coefficientKey (
             sort ( keys( %{ $calibration_samples[ 0 ]->{"coefficients"} } ) ) )
  {
    print FILE_OUT $coefficientKey . "\t";
  }

  print FILE_OUT "\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    #print "full discrete_record: ".Dumper($discrete_record)."\n";
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"} . "\t";
      my $round_CTD_depth =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
      print FILE_OUT $round_CTD_depth . "\t";
      my $round_CTD_Oxy_mL =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Value"} );
      print FILE_OUT $round_CTD_Oxy_mL . "\t";
      my $round_Winkler_Oxy_mL = sprintf( "%8.3f",
                          $discrete_record->{"Cals"}[ $i ]->{"Extract_Value"} );
      print FILE_OUT $round_Winkler_Oxy_mL . "\t";
      my $round_Winkler_stdDev = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Extract_stdDev"} );
      print FILE_OUT $round_Winkler_stdDev . "\t";
      my $round_Winkler_percentStdDev =
          sprintf( "%8.3f",
                   $discrete_record->{"Cals"}[ $i ]->{"Extract_percentStdDev"}
          );
      print FILE_OUT $round_Winkler_percentStdDev . "\t";
      my $round_percentDiff =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"percentDiff"} );
      print FILE_OUT $round_percentDiff . "\t";
      print FILE_OUT $discrete_record->{"Sensor_model"} . "\t";
      print FILE_OUT $discrete_record->{"Sensor_SN"} . "\t";

      # print coefficients
      foreach my $coefficientKey (
                      sort ( keys( %{ $discrete_record->{"coefficients"} } ) ) )
      {
        print FILE_OUT $discrete_record->{"coefficients"}->{$coefficientKey}
            . "\t";
      }

      print FILE_OUT "\n";
    }
  }

  # 'coefficients' => {
  #                              'O2_Boc' => '0.0000',
  #                              'O2_TCor' => '-2.0e-04',
  #                              'O2_Voffset' => '-0.4970',
  #                              'O2_Soc' => '0.4491',
  #                              'eqn' => '2',
  #                              'O2_PCor' => '1.350e-04',
  #                              'cal_date' => 1095836400
  #                            },

  close FILE_OUT;
  return;
}

# END print_discreteO2_v2

#*************************************************************#
#* print_discreteO2_v3: Writes discrete Oxygen data out to a    *#
#* file                                                      *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteO2_v3
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  print FILE_OUT
"Date\tCTD file\tWinkler Depth\tCTD depth\tCTD Oxygen\tWinkler Oxygen\tWinkler Std Dev\t Winkler % Std Dev\tPercent Diff %\tOxygen Model\tOxygen SN\tOxygen Soc\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    #print "full discrete_record: ".Dumper($discrete_record)."\n";
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"} . "\t";
      my $round_CTD_depth =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
      print FILE_OUT $round_CTD_depth . "\t";
      my $round_CTD_Oxy_mL =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Value"} );
      print FILE_OUT $round_CTD_Oxy_mL . "\t";
      my $round_Winkler_Oxy_mL = sprintf( "%8.3f",
                          $discrete_record->{"Cals"}[ $i ]->{"Extract_Value"} );
      print FILE_OUT $round_Winkler_Oxy_mL . "\t";
      my $round_Winkler_stdDev = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Extract_stdDev"} );
      print FILE_OUT $round_Winkler_stdDev . "\t";
      my $round_Winkler_percentStdDev =
          sprintf( "%8.3f",
                   $discrete_record->{"Cals"}[ $i ]->{"Extract_percentStdDev"}
          );
      print FILE_OUT $round_Winkler_percentStdDev . "\t";
      my $round_percentDiff =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"percentDiff"} );
      print FILE_OUT $round_percentDiff . "\t";
      print FILE_OUT $discrete_record->{"Sensor_model"} . "\t";
      print FILE_OUT $discrete_record->{"Sensor_SN"} . "\t";
      print FILE_OUT $discrete_record->{"coefficients"}->{"O2_Soc"} . "\n";

    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteO2_v3

#*************************************************************#
#* print_calibrationsO2: Writes Oxygen calibration data      *#
#* out to a file                                             *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_calibrationsO2
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  print FILE_OUT "\n* column 1: Date and Time mm/dd/yy HH:MM\n";
  print FILE_OUT "* column 2: Day of Year\n";
  print FILE_OUT "* column 3: ORCA Cast file\n";
  print FILE_OUT "* column 4: Oxygen Sensor Model\n";
  print FILE_OUT "* column 5: Oxygen Sensor Serial Number\n";
  print FILE_OUT "* column 6: Winkler depth\n";
  print FILE_OUT "* column 7: Winkler Oxygen concentration, ml/L\n";
  print FILE_OUT "* column 8: Standard deviation between Winkler samples\n";
  print FILE_OUT
      "* column 9: Percent standard deviation between Winkler samples\n";
  print FILE_OUT "* column 10: CTD depth, m (1 meter average)\n";
  print FILE_OUT "* column 11: CTD Pressure (1 meter average), db\n";
  print FILE_OUT "* column 12: CTD Temperature, degrees C (1 meter average)\n";
  print FILE_OUT "* column 13: CTD Salinity, psu (1 meter average)\n";
  print FILE_OUT "* column 14: CTD Oxygen volts (1 meter average)\n";
  print FILE_OUT
      "* column 15: CTD Oxygen saturation, mL/L (1 meter average) \n";
  print FILE_OUT
      "* column 16: CTD Oxygen concentration, mL/L (1 meter average)\n";
  print FILE_OUT
"* column 17: Original CTD Oxygen concentration, ml/L (calculated from averages)\n";
  print FILE_OUT "* column 18: Oxygen coefficient Soc, original\n";
  print FILE_OUT "* column 19: Oxygen coefficient, Voffset, original\n";
  print FILE_OUT "* column 20: Oxygen coefficient, tCor\n";
  print FILE_OUT "* column 21: Oxygen coefficient, pCor\n";
  print FILE_OUT "* column 22: Phi\n";
  print FILE_OUT "* column 23: Winkler/phi\n";
  print FILE_OUT "* column 24: Slope of regression, M\n";
  print FILE_OUT "* column 25: Intercept of regression, b\n";
  print FILE_OUT "* column 26: Corr coeff of regression, R squared\n";
  print FILE_OUT "* column 27: Oxygen coefficient, Soc, calibrated\n";
  print FILE_OUT "* column 28: Oxygen coefficient, Voffset, calibrated\n";
  print FILE_OUT
"* column 29: Calibrated CTD Oxygen concentration, ml/L (calculated from averages)\n";
  print FILE_OUT
"* column 30: Percent difference, Winkler vs Original CTD concentration\n";
  print FILE_OUT
"* column 31: Percent difference, Winkler vs Calibrated CTD concentration\n";
  print FILE_OUT
"* column 32: Percent difference, Calibrated vs Original CTD concentration\n";
  print FILE_OUT "*END HEADER*\n\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my ( $sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst ) =
          localtime $discrete_record->{"time"};
      my $month      = $mon + 1;
      my $year_total = $year + 1900;
      print FILE_OUT "$month\/$day\/$year_total $hour:$min\t";
      my $yday_total = $yday + 1;
      print FILE_OUT $yday_total . "\t";
      print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      print FILE_OUT $discrete_record->{"O2_model"} . "\t";
      print FILE_OUT $discrete_record->{"O2_SN"} . "\t";
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Winkler_depth"} . "\t";
      my $round_Winkler_Oxy_mL = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Winkler_Oxy_mL"} );
      print FILE_OUT $round_Winkler_Oxy_mL . "\t";
      my $round_Winkler_stdDev = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Winkler_stdDev"} );
      print FILE_OUT $round_Winkler_stdDev . "\t";
      my $round_Winkler_percentStdDev =
          sprintf( "%8.3f",
                   $discrete_record->{"Cals"}[ $i ]->{"Winkler_percentStdDev"}
          );
      print FILE_OUT $round_Winkler_percentStdDev . "\t";
      my $round_CTD_depth =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Depth"} );
      print FILE_OUT $round_CTD_depth . "\t";
      my $round_CTD_press =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Press"} );
      print FILE_OUT $round_CTD_press . "\t";
      my $round_CTD_temp =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Temp"} );
      print FILE_OUT $round_CTD_temp . "\t";
      my $round_CTD_sal =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Sal"} );
      print FILE_OUT $round_CTD_sal . "\t";
      my $round_CTD_O2Volts = sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]
                                       ->{"CTD_O2_volts"} );
      print FILE_OUT $round_CTD_O2Volts . "\t";
      my $round_CTD_O2sat = sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]
                                     ->{"CTD_O2sat_ml"} );
      print FILE_OUT $round_CTD_O2sat . "\t";
      my $round_CTD_Oxy_mL =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_O2ml"} );
      print FILE_OUT $round_CTD_Oxy_mL . "\t";
      my $round_CTD_Oxy_mL_orig = sprintf( "%8.3f",
                          $discrete_record->{"Cals"}[ $i ]->{"CTD_O2ml_orig"} );
      print FILE_OUT $round_CTD_Oxy_mL_orig . "\t";
      print FILE_OUT $discrete_record->{"O2_Soc"} . "\t";
      print FILE_OUT $discrete_record->{"O2_Voffset"} . "\t";
      print FILE_OUT $discrete_record->{"O2_tCor"} . "\t";
      print FILE_OUT $discrete_record->{"O2_pCor"} . "\t";
      my $round_phi =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"phi"} );
      print FILE_OUT $round_phi . "\t";
      my $round_wink_phi = sprintf( "%8.3f",
                                    $discrete_record->{"Cals"}[ $i ]
                                        ->{"winklerOverPhi"} );
      print FILE_OUT $round_wink_phi . "\t";
      my $round_m = sprintf( "%8.3f", $discrete_record->{"M"} );
      print FILE_OUT $round_m . "\t";
      my $round_b = sprintf( "%8.3f", $discrete_record->{"B"} );
      print FILE_OUT $round_b . "\t";
      my $round_rsq = sprintf( "%8.3f", $discrete_record->{"Rsq"} );
      print FILE_OUT $round_rsq . "\t";
      print FILE_OUT $discrete_record->{"O2_Soc_cal"} . "\t";
      print FILE_OUT $discrete_record->{"O2_Voffset_cal"} . "\t";
      my $round_CTD_Oxy_mL_cal = sprintf( "%8.3f",
                           $discrete_record->{"Cals"}[ $i ]->{"CTD_O2ml_cal"} );
      print FILE_OUT $round_CTD_Oxy_mL_cal . "\t";
      my $round_winkold = sprintf( "%8.3f",
                                   $discrete_record->{"Cals"}[ $i ]
                                       ->{"percent_diff_winkler_old"} );
      print FILE_OUT $round_winkold . "\t";
      my $round_winknew = sprintf( "%8.3f",
                                   $discrete_record->{"Cals"}[ $i ]
                                       ->{"percent_diff_winkler_new"} );
      print FILE_OUT $round_winknew . "\t";
      my $round_oldnew = sprintf( "%8.3f",
                                  $discrete_record->{"Cals"}[ $i ]
                                      ->{"percent_diff_new_old"} );
      print FILE_OUT $round_oldnew . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_calibrationsO2

#*************************************************************#
#* print_discreteChl: Writes discrete chlorophyll data out   *#
#* to a file                                                 *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteChl
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  print FILE_OUT"\n*** Top of file: Chlorophyll Extraction Values ***\n";
  print FILE_OUT "\n* column 1: Date\n";
  print FILE_OUT "* column 2: CTD file\n";
  print FILE_OUT "* column 3: Depth\n";
  print FILE_OUT "* column 4: Chlorophyll Concentration, mg/m^3\n";
  print FILE_OUT "* column 5: Intentionally left blank\n";
  print FILE_OUT "* column 6: Fo/Fa max\n";
  print FILE_OUT "* column 7: Lini\n";
  print FILE_OUT "* column 8: Kx\n";
  print FILE_OUT "* column 9: Standard\n";
  print FILE_OUT "* column 10: Volume Sampled\n";
  print FILE_OUT "* column 11: Volume Extracted\n";
  print FILE_OUT "* column 12: Blank\n";
  print FILE_OUT "* column 13: Fo\n";
  print FILE_OUT "* column 14: Fa\n";
  print FILE_OUT "* column 15: Dilution factor\n";
  print FILE_OUT "\n*****\n";
  print FILE_OUT
      "\n*** Bottom of file: CTD and Extraction calibration summary\n";
  print FILE_OUT "\n* column 1: Date\n";
  print FILE_OUT "* column 2: CTD file\n";
  print FILE_OUT "* column 3: Extracted Depth\n";
  print FILE_OUT "* column 4: CTD Depth\n";
  print FILE_OUT "* column 5: CTD Chlorophyll, mg/m^3\n";
  print FILE_OUT "* column 6: Extracted Chlorophyll, mg/m^3\n";
  print FILE_OUT "* column 7: Percent Difference\n";
  print FILE_OUT "* column 8: Fluorometer Model\n";
  print FILE_OUT "* column 9: Fluorometer SN\n";

  print FILE_OUT "\n*END HEADER*\n\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $sample_record_index = $#{ $discrete_record->{"samples"} };
    my $i                   = 0;
    for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
    {
      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"depth"} . "\t";
      my $round_Chl =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"Chlr"} );
      print FILE_OUT $round_Chl . "\t";
      print FILE_OUT "\t";
      print FILE_OUT $discrete_record->{"Fm"} . "\t";
      print FILE_OUT $discrete_record->{"Lini"} . "\t";
      print FILE_OUT $discrete_record->{"Kx"} . "\t";
      print FILE_OUT $discrete_record->{"std"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"volSample"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"volExtract"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"blank"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"Fo"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"Fa"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"Dilution"} . "\t";
      print FILE_OUT "\n";
    }
  }

  print FILE_OUT "\n\n*****\n\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = localtime $discrete_record->{"time"};
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"} . "\t";
      my $round_CTD_depth =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
      print FILE_OUT $round_CTD_depth . "\t";
      my $round_CTD_Chl =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Chl"} );
      print FILE_OUT $round_CTD_Chl . "\t";
      my $round_Extract_Chl =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"Extract_Chl"} );
      print FILE_OUT $round_Extract_Chl . "\t";
      my $round_percentDiff =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"percentDiff"} );
      print FILE_OUT $round_percentDiff . "\t";
      print FILE_OUT $discrete_record->{"Fluor_model"} . "\t";
      print FILE_OUT $discrete_record->{"Fluor_SN"} . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteChl

#*************************************************************#
#* print_discreteNut: Writes discrete nutrient data out to   *#
#* a file                                                    *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteNut
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  ### HEADER ###
  # yearday
  # CTD file
  # Depth
  # PO4
  # SiO4
  # NO3
  # NO2
  # NH4

  print FILE_OUT
"Yearday\tCTD file\tDepth\tPO4 (uMol)\tSiO4 (uMol)\tNO3 (uMol)\tNO2 (uMol)\tNH4 (uMol)\t\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $sample_record_index = $#{ $discrete_record->{"samples"} };
    my $i                   = 0;
    for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
    {

      my $print_time = yearday2000( $discrete_record->{"time"} );
      print FILE_OUT $print_time . "\t";
      print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"depth"} . "\t";
      my $round_PO4 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"PO4"} );
      print FILE_OUT $round_PO4 . "\t";
      my $round_SiO4 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"SiO4"} );
      print FILE_OUT $round_SiO4 . "\t";
      my $round_NO3 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"NO3"} );
      print FILE_OUT $round_NO3 . "\t";
      my $round_NO2 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"NO2"} );
      print FILE_OUT $round_NO2 . "\t";
      my $round_NH4 =
          sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"NH4"} );
      print FILE_OUT $round_NH4 . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteNut

#*************************************************************#
#* print_discreteNO3: Writes NO3 discrete samples out to a  *#
#* file                                                      *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteNO3
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  # No header printed so that matlab can load the text file somewhat happily...
  # columns are as follows:
  #
  # Column 1: yearday
  # Column 2: cast
  # Column 3: depth
  # Column 4: discrete NO3

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = yearday2000( $discrete_record->{"time"} );
      print FILE_OUT $print_time . "\t";
      $_ = $discrete_record->{"CAST_file"};
      my $cast;
      if ( /\d*\/\D*\d*_\D*(\d*)/ )
      {
        $cast = $1;

        #print "cast = $cast\n";
      }
      print FILE_OUT $cast . "\t";
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"} . "\t";
      my $round_Extract_Value = sprintf( "%8.3f",
                          $discrete_record->{"Cals"}[ $i ]->{"Extract_Value"} );
      print FILE_OUT $round_Extract_Value . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteNO3

#*************************************************************#
#* print_discreteO2_basic: Writes discrete O2 sample         *#
#* out to a file                                             *#
#*                                                           *#
#* Input to function: data structure, file name              *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteO2_basic
{
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibrations samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  # No header printed so that matlab can load the text file somewhat happily...
  # columns are as follows:
  #
  # Column 1: yearday
  # Column 2: cast
  # Column 3: depth
  # Column 4: discrete O2 (ml/l)

  foreach my $discrete_record ( @calibration_samples )
  {
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = yearday2000( $discrete_record->{"time"} );
      print FILE_OUT $print_time . "\t";
      $_ = $discrete_record->{"CAST_file"};
      my $cast;
      if ( /\d*\/\D*\d*_\D*(\d*)/ )
      {
        $cast = $1;

        #print "cast = $cast\n";
      }
      print FILE_OUT $cast . "\t";
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Winkler_depth"} . "\t";
      my $round_Winkler_Oxy_mL = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Winkler_Oxy_mL"} );
      print FILE_OUT $round_Winkler_Oxy_mL . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteO2_basic

#*************************************************************#
#* print_discrete: Writes discrete data out to a file        *#
#*                                                           *#
#* Input to function: data type, data structure, file name   *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discrete
{
  my $dataType    = shift;
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibration samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  if ( $dataType == "Fluor" )
  {
    print FILE_OUT"\n*** Top of file: Chlorophyll Extraction Values ***\n";
    print FILE_OUT "\n* column 1: Date\n";
    print FILE_OUT "* column 2: CTD file\n";
    print FILE_OUT "* column 3: Depth\n";
    print FILE_OUT "* column 4: Chlorophyll Concentration, mg/m^3\n";
    print FILE_OUT "* column 5: Intentionally left blank\n";
    print FILE_OUT "* column 6: Fo/Fa max\n";
    print FILE_OUT "* column 7: Lini\n";
    print FILE_OUT "* column 8: Kx\n";
    print FILE_OUT "* column 9: Standard\n";
    print FILE_OUT "* column 10: Volume Sampled\n";
    print FILE_OUT "* column 11: Volume Extracted\n";
    print FILE_OUT "* column 12: Blank\n";
    print FILE_OUT "* column 13: Fo\n";
    print FILE_OUT "* column 14: Fa\n";
    print FILE_OUT "* column 15: Dilution factor\n";
    print FILE_OUT "\n*****\n";
    print FILE_OUT
        "\n*** Bottom of file: CTD and Extraction calibration summary\n";
    print FILE_OUT "\n* column 1: Date\n";
    print FILE_OUT "* column 2: CTD file\n";
    print FILE_OUT "* column 3: Extracted Depth\n";
    print FILE_OUT "* column 4: CTD Depth\n";
    print FILE_OUT "* column 5: CTD Chlorophyll, mg/m^3\n";
    print FILE_OUT "* column 6: Extracted Chlorophyll, mg/m^3\n";
    print FILE_OUT "* column 7: Percent Difference\n";
    print FILE_OUT "* column 8: Fluorometer Model\n";
    print FILE_OUT "* column 9: Fluorometer SN\n";

    print FILE_OUT "\n*END HEADER*\n\n";

    foreach my $discrete_record ( @calibration_samples )
    {
      print FILE_OUT "\n";
      my $sample_record_index = $#{ $discrete_record->{"samples"} };
      my $i                   = 0;
      for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
      {
        my $print_time = localtime $discrete_record->{"time"};
        print FILE_OUT $print_time . "\t";
        if ( $discrete_record->{"cast_type"} eq "Profile" )
        {
          print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
        } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                  || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
        {
          print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"discFile"}
              . "\t";
        }
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"depth"} . "\t";
        my $round_Chl =
            sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"Chlr"} );
        print FILE_OUT $round_Chl . "\t";
        print FILE_OUT "\t";
        print FILE_OUT $discrete_record->{"Fm"} . "\t";
        print FILE_OUT $discrete_record->{"Lini"} . "\t";
        print FILE_OUT $discrete_record->{"Kx"} . "\t";
        print FILE_OUT $discrete_record->{"std"} . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"volSample"}
            . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"volExtract"}
            . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"blank"} . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"Fo"} . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"Fa"} . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"Dilution"} . "\t";
        print FILE_OUT "\n";
      }
    }

    print FILE_OUT "\n\n*****\n\n";

    foreach my $discrete_record ( @calibration_samples )
    {
      print FILE_OUT "\n";
      my $cal_record_index = $#{ $discrete_record->{"Cals"} };
      my $i                = 0;
      for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
      {

        my $print_time = localtime $discrete_record->{"time"};
        print FILE_OUT $print_time . "\t";
        if ( $discrete_record->{"cast_type"} eq "Profile" )
        {
          print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
        } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                  || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
        {
          print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"discFile"} . "\t";
        }
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"}
            . "\t";
        my $round_CTD_depth =
            sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
        print FILE_OUT $round_CTD_depth . "\t";
        my $round_CTD_Sensor =
            sprintf( "%8.3f",
                     $discrete_record->{"Cals"}[ $i ]->{"CTD_Sensor"} );
        print FILE_OUT $round_CTD_Sensor . "\t";
        my $round_Extract_Sensor = sprintf( "%8.3f",
                         $discrete_record->{"Cals"}[ $i ]->{"Extract_Sensor"} );
        print FILE_OUT $round_Extract_Sensor . "\t";
        my $round_percentDiff = sprintf( "%8.3f",
                            $discrete_record->{"Cals"}[ $i ]->{"percentDiff"} );
        print FILE_OUT $round_percentDiff . "\t";
        print FILE_OUT $discrete_record->{"Sensor_model"} . "\t";
        print FILE_OUT $discrete_record->{"Sensor_SN"} . "\t";
        print FILE_OUT "\n";
      }
    }

  } elsif ( $dataType == "NO3" )
  {    # end if $data_type = Fluor

    print FILE_OUT"\n*** Top of file: Nutrient Extraction Values ***\n";
    print FILE_OUT "\n* column 1: Date\n";
    print FILE_OUT "* column 2: ORCA Cast file\n";
    print FILE_OUT "* column 3: Depth\n";
    print FILE_OUT "* column 4: PO4 Concentration, uMol\n";
    print FILE_OUT "* column 5: SiO4 Concentration, uMol\n";
    print FILE_OUT "* column 6: NO3 Concentration, uMol\n";
    print FILE_OUT "* column 7: NO2 Concentration, uMol\n";
    print FILE_OUT "* column 8: NH4 Concentration, uMol\n";
    print FILE_OUT "\n*****\n";
    print FILE_OUT
        "\n*** Bottom of file: CTD and Extraction calibration summary\n";
    print FILE_OUT "\n* column 1: Date\n";
    print FILE_OUT "* column 2: ORCA Cast file\n";
    print FILE_OUT "* column 3: Extracted Depth\n";
    print FILE_OUT "* column 4: CTD Depth\n";
    print FILE_OUT "* column 5: CTD NO3, uMol\n";
    print FILE_OUT "* column 6: Extracted NO3, uMol\n";
    print FILE_OUT "* column 8: ISUS Model\n";
    print FILE_OUT "* column 9: ISUS SN\n";

    print FILE_OUT "\n*END HEADER*\n\n";

    foreach my $discrete_record ( @calibration_samples )
    {
      print FILE_OUT "\n";
      my $sample_record_index = $#{ $discrete_record->{"samples"} };
      my $i                   = 0;
      for ( $i = 0 ; $i <= $sample_record_index ; $i++ )
      {
        my $print_time = localtime $discrete_record->{"time"};
        print FILE_OUT $print_time . "\t";
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
        print FILE_OUT $discrete_record->{"samples"}[ $i ]->{"depth"} . "\t";
        my $round_PO4 =
            sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"PO4"} );
        print FILE_OUT $round_PO4 . "\t";
        my $round_SiO4 =
            sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"SiO4"} );
        print FILE_OUT $round_SiO4 . "\t";
        my $round_NO3 =
            sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"NO3"} );
        print FILE_OUT $round_NO3 . "\t";
        my $round_NO2 =
            sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"NO2"} );
        print FILE_OUT $round_NO2 . "\t";
        my $round_NH4 =
            sprintf( "%8.3f", $discrete_record->{"samples"}[ $i ]->{"NH4"} );
        print FILE_OUT $round_NH4 . "\t";
        print FILE_OUT "\n";
      }
    }

    print FILE_OUT "\n\n*****\n\n";

    foreach my $discrete_record ( @calibration_samples )
    {
      print FILE_OUT "\n";
      my $cal_record_index = $#{ $discrete_record->{"Cals"} };
      my $i                = 0;
      for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
      {

        my $print_time = localtime $discrete_record->{"time"};
        print FILE_OUT $print_time . "\t";
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"}
            . "\t";
        my $round_CTD_depth =
            sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
        print FILE_OUT $round_CTD_depth . "\t";
        my $round_CTD_Sensor =
            sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Value"} );
        print FILE_OUT $round_CTD_Sensor . "\t";
        my $round_Extract_Sensor = sprintf( "%8.3f",
                          $discrete_record->{"Cals"}[ $i ]->{"Extract_Value"} );
        print FILE_OUT $round_Extract_Sensor . "\t";
        print FILE_OUT $discrete_record->{"Sensor_model"} . "\t";
        print FILE_OUT $discrete_record->{"Sensor_SN"} . "\t";
        print FILE_OUT "\n";
      }
    }

  }

  close FILE_OUT;
  return;
}

# END print_discrete

#*************************************************************#
#* print_discreteV2: Writes discrete data out to a file       *#
#*                                                           *#
#* Input to function: data type, data structure, file name   *#
#* Returns to main: writes file, returns nothing to main     *#
#*************************************************************#
sub print_discreteV2
{
  my $dataType    = shift;
  my $report_file = shift;
  my $data        = shift;

  my @calibration_samples = @{$data};

#print "report file!!! $report_file \n";
#print "calibration samples as seen in PRINT!!! =".Dumper(\@calibration_samples)."\n";

  open FILE_OUT, ">$report_file" or die "Cannot open $report_file!!!!!\n";

  ### HEADER ###
  # yearday
  # CTD file
  # sensor model
  # sensor SN
  # sample depth
  # sensor depth
  # sensor reading
  # extracted sample
  # percent difference

  print FILE_OUT
"Yearday\tCTD file\tSensor Model\tSensor SN\tSample depth (m)\tSensor depth (m)\tSensor Reading\tExtracted Sample\tPercent Difference\n";

  foreach my $discrete_record ( @calibration_samples )
  {
    #print "full discrete record: ".Dumper($discrete_record)."\n";
    print FILE_OUT "\n";
    my $cal_record_index = $#{ $discrete_record->{"Cals"} };
    my $i                = 0;
    for ( $i = 0 ; $i <= $cal_record_index ; $i++ )
    {

      my $print_time = yearday2000( $discrete_record->{"time"} );
      print FILE_OUT $print_time . "\t";
      if ( $discrete_record->{"cast_type"} eq "Profile" )
      {
        print FILE_OUT $discrete_record->{"CAST_file"} . "\t";
      } elsif (    ( $discrete_record->{"cast_type"} eq "Discrete" )
                || ( $discrete_record->{"cast_type"} eq "Mixed" ) )
      {
        print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"discFile"} . "\t";
      }
      print FILE_OUT $discrete_record->{"Sensor_model"} . "\t";
      print FILE_OUT $discrete_record->{"Sensor_SN"} . "\t";
      print FILE_OUT $discrete_record->{"Cals"}[ $i ]->{"Extract_depth"} . "\t";
      my $round_CTD_depth =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_depth"} );
      print FILE_OUT $round_CTD_depth . "\t";
      my $round_CTD_Sensor =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"CTD_Value"} );
      print FILE_OUT $round_CTD_Sensor . "\t";
      my $round_Extract_Sensor = sprintf( "%8.3f",
                          $discrete_record->{"Cals"}[ $i ]->{"Extract_Value"} );
      print FILE_OUT $round_Extract_Sensor . "\t";
      my $round_percentDiff =
          sprintf( "%8.3f", $discrete_record->{"Cals"}[ $i ]->{"percentDiff"} );
      print FILE_OUT $round_percentDiff . "\t";
      print FILE_OUT "\n";
    }
  }

  close FILE_OUT;
  return;
}

# END print_discreteV2

############################ END FILE #################################################
1;

