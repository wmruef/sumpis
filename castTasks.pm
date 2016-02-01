#!/usr/bin/perl
package castTasks;

use strict;
use Time::Local;
use Data::Dumper;
use stats;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA         = qw(Exporter);
@EXPORT      = qw(align_array find_downcast_old find_downcast align);
@EXPORT_OK   = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* align_array: returns shift of array 2 relative to array 1 *#
#* corresponding to the correlation coefficient value        *#
#* closest to 1                                              *#
#* Input to function: array 1, array 2                       *#
#* Returns to main: alignment shift (i.e. 5)                 *#
#*************************************************************#
sub align_array
{
  my $array_ref_one = shift;
  my $array_ref_two = shift;

  my $array_corrcoef = corrcoef( $array_ref_two, $array_ref_one );

  #print "Array2 = " . Dumper( $array_ref_two ) . "\n";
  #print "Begining cc = $array_corrcoef\n";
  my $previous_corrcoef   = 0;
  my $array_shift_counter = 0;
  while ( abs( $array_corrcoef ) > abs( $previous_corrcoef ) )
  {
    $previous_corrcoef = $array_corrcoef;
    shift( @{$array_ref_two} );
    pop( @{$array_ref_one} );
    $array_corrcoef = corrcoef( $array_ref_two, $array_ref_one );
    $array_shift_counter++;

    #print "Alignment: num=$array_shift_counter  cc=$array_corrcoef\n";
  }

  #print "Array1 = " . Dumper( $array_ref_two ) . "\n";
  #print "Array Size = " . $#{$array_ref_two } . "\n";

  my $alignment = $array_shift_counter - 1;

  #print "alignment = $alignment\n";
  return $alignment;
}

# END align_array subroutine

#*************************************************************#
#* find_downcast_old: Find the index of start and end of     *#
#* downcast                                                  *#
#* Input to function: cnv_data array                         *#
#* Returns to main: index of start and end of downcast       *#
#*************************************************************#
sub find_downcast_old
{
  my $cast_data            = shift;
  my $num_of_down_records  = 0;
  my $index_start_downcast = -1;
  my $index_end_downcast   = -1;

  #print "Cast DATA " . Dumper( $cast_data ) . "\n";
  for ( my $i = 0 ; $i <= $#{$cast_data} ; $i++ )
  {
    if ( $i > 0 )
    {
      if ( $cast_data->[ $i ]->{"Press_db"} >
           $cast_data->[ $i - 1 ]->{"Press_db"} )
      {
        $num_of_down_records++;
      } else
      {
        if ( $num_of_down_records > 5 )
        {
          $cast_data->[ $i ]->{"Press_db"};
          $index_end_downcast = $i - 1;
          last;
        }
        $num_of_down_records = 0;
      }
    }
    if ( $num_of_down_records == 5 )
    {
      $index_start_downcast = $i - 5;
    }
  }
  if ( $index_end_downcast == -1 ) { $index_end_downcast = $#{$cast_data}; }
  return ( $index_start_downcast, $index_end_downcast );
}

# END find_downcast_old subroutine

#*************************************************************#
#* find_downcast : Finds the beginning and end of each cast  *#
#* segment by finding the peaks of the second derivative of  *#
#* pressure.                                                 *#
#* Input to function: data hash with Scan and Press          *#
#* Returns to main: 4 data arrays, corresponding to upcast   *#
#* begining and end, and downcast beginning and end          *#
#*************************************************************#

sub find_downcast
{

  my $scanRef     = shift;
  my $pressRef    = shift;
  my $sample_rate = shift;

  # print "sample rate: $sample_rate\n";

  my @Scan_raw  = @{$scanRef};
  my @Press_raw = @{$pressRef};

  # print Dumper(\@Scan_raw) ."\n";
  # print Dumper(\@Press_raw) ."\n";

  my $W_incrementor = 0;
  my @Scan          = ();
  my @Press         = ();
  for ( my $Z = 0 ;
        $Z <= ( ( $#Press_raw / $sample_rate ) - $sample_rate ) ;
        $Z++ )
  {
    #my $test1 = $W_incrementor;
    #my $test2 = $W_incrementor + $sample_rate-1;
    #print "test1: $test1 test2: $test2\n";
    my @average_bin = map { $_ }
        @Press_raw[ $W_incrementor .. ( $W_incrementor + $sample_rate - 1 ) ];
    $Scan[ $Z ]    = $Z;
    $Press[ $Z ]   = average( \@average_bin );
    $W_incrementor = $W_incrementor + $sample_rate;

    #print "Z: $Z W: $W_incrementor\n";
  }

  #print Dumper(\@Scan)."\n";
  #print Dumper(\@Press)."\n";

  my @second_derivative = lsfderive( \@Scan, \@Press );

  #print "second derivative ".Dumper(\@second_derivative)."\n";
  my @scan2 = map { $_ } @Scan[ 0 .. $#second_derivative ];

  #print "scan2 ".Dumper(\@scan2)."\n";
  my $mins_index  = 0;
  my $maxs_index  = 0;
  my @derive_mins = ();
  my @derive_maxs = ();
  for ( my $i = 0 ; $i <= $#second_derivative - 1 ; $i++ )
  {
    if ( $second_derivative[ $i ] < -0.007 )
    {
      $derive_mins[ $mins_index ]->{'Scan'}     = $scan2[ $i ];
      $derive_mins[ $mins_index ]->{'Min_peak'} = $second_derivative[ $i ];
      $mins_index++;
    } elsif ( $second_derivative[ $i ] > 0.007 )
    {
      $derive_maxs[ $maxs_index ]->{'Scan'}     = $scan2[ $i ];
      $derive_maxs[ $maxs_index ]->{'Max_peak'} = $second_derivative[ $i ];
      $maxs_index++;
    }
  }

  #print "Derive Mins: ".Dumper(\@derive_mins)."\n";
  #print "Derive Maxs: ".Dumper(\@derive_maxs)."\n";

  my $min_index = 0;
  my @peak_min  = ();
  for ( my $j = 1 ; $j < $#derive_mins ; $j++ )
  {
    if (
       (
         $derive_mins[ $j - 1 ]->{'Min_peak'} > $derive_mins[ $j ]->{'Min_peak'}
       )
       && ( $derive_mins[ $j + 1 ]->{'Min_peak'} >
            $derive_mins[ $j ]->{'Min_peak'} )
        )
    {
      $peak_min[ $min_index ] = $derive_mins[ $j ]->{'Scan'};
      $min_index++;
    }
  }

  #print "Peak Mins: ".Dumper(\@peak_min)."\n";

  my $max_index = 0;
  my @peak_max  = ();
  for ( my $k = 1 ; $k < $#derive_maxs ; $k++ )
  {
    if (
       (
         $derive_maxs[ $k - 1 ]->{'Max_peak'} < $derive_maxs[ $k ]->{'Max_peak'}
       )
       && ( $derive_maxs[ $k + 1 ]->{'Max_peak'} <
            $derive_maxs[ $k ]->{'Max_peak'} )
        )
    {
      $peak_max[ $max_index ] = $derive_maxs[ $k ]->{'Scan'};
      $max_index++;
    }
  }

  #print "Peak Maxs: ".Dumper(\@peak_max)."\n";

  my $upcast_begin_index   = 0;
  my @upcast_begin         = ();
  my $upcast_end_index     = 0;
  my @upcast_end           = ();
  my $downcast_begin_index = 0;
  my @downcast_begin       = ();
  my $downcast_end_index   = 0;
  my @downcast_end         = ();

  for ( my $m = 0 ; $m <= $#peak_min ; $m++ )
  {
    if ( $Press[ $peak_min[ $m ] ] > $Press[ $peak_min[ $m ] + 20 ] )
    {
      $upcast_begin[ $upcast_begin_index ] =
          ( $peak_min[ $m ] * $sample_rate ) + 12;
      $upcast_begin_index++;
    } elsif ( $Press[ $peak_min[ $m ] ] > $Press[ $peak_min[ $m ] - 20 ] )
    {
      $downcast_end[ $downcast_end_index ] =
          ( $peak_min[ $m ] * $sample_rate ) + 12;
      $downcast_end_index++;
    }
  }
  for ( my $n = 0 ; $n <= $#peak_max ; $n++ )
  {
    if ( $Press[ $peak_max[ $n ] ] < $Press[ $peak_max[ $n ] + 20 ] )
    {
      $downcast_begin[ $downcast_begin_index ] =
          ( $peak_max[ $n ] * $sample_rate ) + 12;
      $downcast_begin_index++;
    } elsif ( $Press[ $peak_max[ $n ] ] < $Press[ $peak_max[ $n ] - 20 ] )
    {
      $upcast_end[ $upcast_end_index ] =
          ( $peak_max[ $n ] * $sample_rate ) + 12;
      $upcast_end_index++;
    }
  }
  if ( $#peak_max < $#peak_min )
  {
    $upcast_end[ $upcast_end_index ] = $#Scan_raw;
  } elsif ( $#peak_max > $#peak_min )
  {
    $downcast_end[ $downcast_end_index ] = $#Scan_raw;
  }

  #print "upcast begin:".Dumper(\@upcast_begin)."\n";
  #print "upcast end:".Dumper(\@upcast_end)."\n";
  #print "downcast begin:".Dumper(\@downcast_begin)."\n";
  #print "downcast end:".Dumper(\@downcast_end)."\n";

  return ( \@upcast_begin, \@upcast_end, \@downcast_begin, \@downcast_end );

}

# END find_downcast subroutine

#*************************************************************#
#* align : Finds the alignment shift of an array based on    *#
#* the minimum value of the sum of squared difference        *#
#* between the upcast and the downcast.                      *#
#* Input to function: data hash with Scan, Press, Temp, and  *#
#* Parameter (Oxygen, Fluor, etc)                            *#
#* Returns to main: alignment coefficient                    *#
#*************************************************************#

sub align
{
  my $scanRef     = shift;
  my $pressRef    = shift;
  my $tempRef     = shift;
  my $paramRef    = shift;
  my $sample_rate = shift;

  my @Scan   = @{$scanRef};
  my @Press  = @{$pressRef};
  my @Temp   = @{$tempRef};
  my @Oxygen = @{$paramRef};

  # FIND DOWNCAST #

  my @downcast_data  = find_downcast( \@Scan, \@Press, $sample_rate );
  my @upcast_begin   = @{ $downcast_data[ 0 ] };
  my @upcast_end     = @{ $downcast_data[ 1 ] };
  my @downcast_begin = @{ $downcast_data[ 2 ] };
  my @downcast_end   = @{ $downcast_data[ 3 ] };

  #print "upcast start data:".Dumper(\@upcast_begin)."\n";
  #print "upcast end data:".Dumper(\@upcast_end)."\n";
  #print "downcast start data:".Dumper(\@downcast_begin)."\n";
  #print "downcast end data:".Dumper(\@downcast_end)."\n";

  my $array_shift_counter = 0;
  my @SumOxyDiff_array    = ();
  for ( my $A = 0 ; $A < 30 ; $A++ )
  {
    my $SumOxyDiff = 0;

    # EXTRACT UP AND DOWNCAST
    my $UPCAST_start_print = $upcast_begin[ 0 ];
    my $UPCAST_end_print   = $upcast_end[ 0 ];

    #print "Upcast: $UPCAST_start_print : $UPCAST_end_print \n";
    my @UP_temp = map { $_ } @Temp[ $upcast_begin[ 0 ] .. $upcast_end[ 0 ] ];
    my @UP_oxy  = map { $_ } @Oxygen[ $upcast_begin[ 0 ] .. $upcast_end[ 0 ] ];
    my @DOWN_temp = ();
    my @DOWN_oxy  = ();

    #print "upcast begin size....".$#upcast_begin."\n";
    if ( $#upcast_begin > 0 )
    {
      my @UP_temp2 =
          map { $_ }
          @Temp[ $upcast_begin[ 1 ] .. $upcast_end[ 1 ] -
          $array_shift_counter ];
      my @UP_oxy2 =
          map { $_ }
          @Oxygen[ $upcast_begin[ 1 ] .. $upcast_end[ 1 ] -
          $array_shift_counter ];
      push @UP_temp, @UP_temp2;
      push @UP_oxy,  @UP_oxy2;
      @DOWN_temp =
          map { $_ } @Temp[ $downcast_begin[ 0 ] .. $downcast_end[ 0 ] ];
      @DOWN_oxy =
          map { $_ } @Oxygen[ $downcast_begin[ 0 ] .. $downcast_end[ 0 ] ];
    } elsif ( $#upcast_begin == 0 )
    {
      #my $print_downcast_end = $downcast_end[0];
      #print "downcast end = $print_downcast_end\n";
      @DOWN_temp =
          map { $_ }
          @Temp[ $downcast_begin[ 0 ] .. $downcast_end[ 0 ] -
          $array_shift_counter ];
      @DOWN_oxy =
          map { $_ }
          @Oxygen[ $downcast_begin[ 0 ] .. $downcast_end[ 0 ] -
          $array_shift_counter ];
    }

    #print "Upcast temp: ".Dumper(\@UP_temp)."\n";
    #print "Upcast oxy: ".Dumper(\@UP_oxy)."\n";
    #print "Downcast temp: ".Dumper(\@DOWN_temp)."\n";
    #print "Downcast oxy: ".Dumper(\@DOWN_oxy)."\n";
    # BIN DOWN AND UPCAST BY TEMP
    my $temp_bin         = 7;
    my $temp_incrementor = 0.1;
    my @DOWN_bins        = ();
    my $downIndex        = 0;
    my @UP_bins          = ();
    my $upIndex          = 0;

    for ( my $i = 0 ; $i < 60 ; $i++ )
    {
      my $numberInDownBin = 0;
      my @DownBin         = ();
      my $matchDown       = 0;
      my $matchUp         = 0;
      for ( my $j = 0 ; $j <= $#DOWN_temp ; $j++ )
      {
        if ( ( $DOWN_temp[ $j ] >= $temp_bin ) &
             ( $DOWN_temp[ $j ] < $temp_bin + $temp_incrementor ) )
        {
          $DownBin[ $numberInDownBin ] = $DOWN_oxy[ $j ];
          $numberInDownBin++;
          $matchDown = 1;

          #print "Number in down bin inside loop: $numberInDownBin\n";
          #print "J : $j\n";
          #print "Size of DownBin: ".$#DownBin."\n";
        }
      }

      #print "DownBin:".Dumper(\@DownBin)."\n";
      #print "Number in down bin...: $numberInDownBin\n";
      if ( $matchDown == 1 )
      {
        $DOWN_bins[ $downIndex ]->{"Temp"} = $temp_bin;
        if ( $numberInDownBin > 0 )
        {
          $DOWN_bins[ $downIndex ]->{"Oxygen"} = average( \@DownBin );
        } else
        {
          $DOWN_bins[ $downIndex ]->{"Oxygen"} = $DownBin[ $numberInDownBin ];
        }
      }

      #print "DownBins: ".Dumper(\@DOWN_bins)."\n";
      my $numberInUpBin = 0;
      my @UpBin         = ();
      for ( my $j = 0 ; $j <= $#UP_temp ; $j++ )
      {
        if ( ( $UP_temp[ $j ] >= $temp_bin ) &
             ( $UP_temp[ $j ] < $temp_bin + $temp_incrementor ) )
        {
          $UpBin[ $numberInUpBin ] = $UP_oxy[ $j ];
          $numberInUpBin++;
          $matchUp = 2;
        }
      }
      if ( $matchUp == 2 )
      {
        $UP_bins[ $upIndex ]->{"Temp"} = $temp_bin;
        if ( $numberInUpBin > 0 )
        {
          $UP_bins[ $upIndex ]->{"Oxygen"} = average( \@UpBin );
        } else
        {
          $UP_bins[ $upIndex ]->{"Oxygen"} = $UpBin[ $numberInUpBin ];
        }
      }

      #print "UpBins: ".Dumper(\@UP_bins)."\n";
      my $matchUpDown = $matchDown + $matchUp;
      if ( $matchUpDown == 3 )
      {
        my $up_oxy_print   = $UP_bins[ $upIndex ]->{"Oxygen"};
        my $down_oxy_print = $DOWN_bins[ $downIndex ]->{"Oxygen"};

#print "Temp_bin = $temp_bin Oxy_UP = $up_oxy_print Oxy_DOWN = $down_oxy_print\n";
        $SumOxyDiff =
            ( $UP_bins[ $upIndex ]->{"Oxygen"} -
              $DOWN_bins[ $downIndex ]->{"Oxygen"} )**2 +
            $SumOxyDiff;
      }
      $temp_bin = $temp_bin + $temp_incrementor;

      #print "SumOxyDiff in bin loop: $SumOxyDiff\n";
      #print "Temp bin in bin loop: $temp_bin\n";
      $downIndex++;
      $upIndex++;
    }
    $SumOxyDiff_array[ $A ] = $SumOxyDiff;

    #print "SumOxyDiff: $SumOxyDiff\n";
    #print "array shift counter: $array_shift_counter\n";
    shift( @Oxygen );
    pop( @Temp );
    $array_shift_counter++;
  }

  #print "SumOxyDiff_array: ".Dumper(\@SumOxyDiff_array)."\n";
  ( my $alignment_value, my $alignment_index ) = min( \@SumOxyDiff_array );

  #print "Alignment is: $alignment_index \n";
  return $alignment_index;

}    # END align subroutine

1;
