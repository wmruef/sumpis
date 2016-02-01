#!/usr/bin/perl

package stats;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;

@ISA = qw(Exporter);
@EXPORT =
    qw(log10 average average_best corrcoef covariance regression stdev lsfderive min max);
@EXPORT_OK = qw();
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#*************************************************************#
#* log10: Find the log base 10 of a number                   *#
#* Input to function: numer                                  *#
#* Returns to main: log base 10 of number                    *#
#*************************************************************#
sub log10
{
  my $n = shift;
  return log( $n ) / log( 10 );
}

# END log10 subroutine

#*************************************************************#
#* average: Find the average of an array                     *#
#* Input to function: array                                  *#
#* Returns to main: average of an array                      *#
#*************************************************************#
sub average
{
  my $array_reference = shift;

  my $array_max_index = $#{$array_reference};
  if ( $array_max_index == -1 )
  {
    return 0;
  }
  my $array_sum     = 0;
  my $i             = 0;
  my $array_average = 0;

  for ( $i = 0 ; $i <= $array_max_index ; $i++ )
  {
    $array_sum += $array_reference->[ $i ];
  }

  $array_average = $array_sum / ( $array_max_index + 1 );
  return $array_average;
}

# END average subroutine

#*************************************************************#
#* average_best : returns the average of an array with the   *#
#* highest precision (using at least the minimun number of   *#
#* elements specified in input; must be at least 2)          *#
#* Input to function: array, min. number of elements to use  *#
#* Returns to main: average, standard deviation, % precision *#
#*************************************************************#
sub average_best
{
  my $array_reference = shift;

  #print average([1,2,3]);
  my $array_max_index = $#{$array_reference};
  if ( $array_max_index < 1 )
  {
    ###return 0;
    return $array_reference->[ 0 ];
  }
  my $i = 0;
  my $j = 0;

  my $best_average         = 0;
  my $best_std_dev         = 0;
  my $best_percent_std_dev = 0;

  my $average_all = average( $array_reference );

  #print "Average all = $average_all\n";
  my $std_dev_all = stdev( $array_reference );
  my $percent_std_dev_all = ( ( $std_dev_all * 100 ) / $average_all );

  my $inter_average         = 0;
  my $inter_std_dev         = 0;
  my $inter_percent_std_dev = 0;

  my $current_average         = $average_all;
  my $current_std_dev         = $std_dev_all;
  my $current_percent_std_dev = $percent_std_dev_all;

  for ( $i = 0 ; $i <= $array_max_index ; $i++ )
  {
    for ( $j = $i + 1 ; $j <= $array_max_index ; $j++ )
    {
      $inter_average =
          average( [ $array_reference->[ $i ], $array_reference->[ $j ] ] );
      $inter_std_dev =
          stdev( [ $array_reference->[ $i ], $array_reference->[ $j ] ] );
      $inter_percent_std_dev = ( ( $inter_std_dev * 100 ) / $inter_average );
      if ( $inter_percent_std_dev < $current_percent_std_dev )
      {
        $current_percent_std_dev = $inter_percent_std_dev;
        $current_average         = $inter_average;
        $current_std_dev         = $inter_std_dev;
      }
    }
  }
  return ( $current_average, $current_std_dev, $current_percent_std_dev );
}

# END average_best subroutine

#*************************************************************#
#* corrcoef: Find the correlation coefficient of two arrays  *#
#* Input to function: array 1, array 2                       *#
#* Returns to main: correlation coefficient of the 2 arrays  *#
#*************************************************************#
sub corrcoef
{
  my $array_ref_one = shift;
  my $array_ref_two = shift;

  my $array_one_max_index = $#{$array_ref_one};
  my $array_two_max_index = $#{$array_ref_two};

  if (    $array_one_max_index != $array_two_max_index
       || $array_one_max_index == -1
       || $array_two_max_index == -1 )
  {
    return "NAN";
  }

  my $corrcoef =
      covariance( $array_ref_one, $array_ref_two ) /
      sqrt( covariance( $array_ref_one, $array_ref_one ) *
            covariance( $array_ref_two, $array_ref_two ) );
  return $corrcoef;
}

# END corrcoef subroutine

#*************************************************************#
#* covariance: Find the covariance of two arrays             *#
#* Input to function: array 1, array 2                       *#
#* Returns to main: covariance of the 2 arrays               *#
#*************************************************************#
sub covariance
{
  my $array_ref_one = shift;
  my $array_ref_two = shift;

  my $array_one_max_index = $#{$array_ref_one};
  my $array_two_max_index = $#{$array_ref_two};

  if (    $array_one_max_index != $array_two_max_index
       || $array_one_max_index == -1
       || $array_two_max_index == -1 )
  {
    return "NAN";
  }

  my $array_ave_one = average( $array_ref_one );
  my $array_ave_two = average( $array_ref_two );
  my $i             = 0;
  my $sumthing      = 0;

  for ( $i = 0 ; $i <= $array_one_max_index ; $i++ )
  {
    $sumthing +=
        ( $array_ref_one->[ $i ] - $array_ave_one ) *
        ( $array_ref_two->[ $i ] - $array_ave_two );
  }

  my $covariance = $sumthing / ( $array_one_max_index + 1 );
  return $covariance;
}

# END covariance subroutine

#*************************************************************#
#* max: finds the maximum value of an array                  *#
#* Input to function: array                                  *#
#* Returns to main: index location and value of array max    *#
#*************************************************************#
sub max
{
  my $array_reference = shift;
  my $array_max_index = $#{$array_reference};

  if ( $array_max_index == -1 )
  {
    return 0;
  }
  my $array_max = $array_reference->[ 0 ];
  my $index     = 0;

  for ( my $i = 1 ; $i <= $array_max_index ; $i++ )
  {
#print "i:$i array: ".$array_reference->[$i]." max: $array_max index: $index\n";
    if ( $array_reference->[ $i ] > $array_max )
    {
      #print "storing new max and index!\n";
      $array_max = $array_reference->[ $i ];
      $index     = $i;
    }
  }
  return ( $array_max, $index );
}

# END max subroutine

#*************************************************************#
#* min: finds the minimum value of an array                  *#
#* Input to function: array                                  *#
#* Returns to main: index location and value of array min    *#
#*************************************************************#
sub min
{
  my $array_reference = shift;
  my $array_max_index = $#{$array_reference};

  if ( $array_max_index == -1 )
  {
    return 0;
  }
  my $array_min = $array_reference->[ 0 ];
  my $index     = 0;

  for ( my $i = 1 ; $i <= $array_max_index ; $i++ )
  {
#print "i:$i array: ".$array_reference->[$i]." min: $array_min index: $index\n";
    if ( $array_reference->[ $i ] < $array_min )
    {
      #print "storing new min and index!\n";
      $array_min = $array_reference->[ $i ];
      $index     = $i;
    }
  }
  return ( $array_min, $index );
}

# END min subroutine

#*************************************************************#
#* regression: Calculates the linear regression between two  *#
#* arrays, according to the equation: y = Mx + B             *#
#* Input to function: array 1, array 2                       *#
#* Returns to main: slope and y-intercept (M and B)          *#
#*************************************************************#
sub regression
{
  my $array_ref_one = shift;
  my $array_ref_two = shift;

  my $array_one_max_index = $#{$array_ref_one};
  my $array_two_max_index = $#{$array_ref_two};

  if (    $array_one_max_index != $array_two_max_index
       || $array_one_max_index == -1
       || $array_two_max_index == -1 )
  {
    return "NAN";
  }

  my $sumx  = 0;
  my $sumx2 = 0;
  my $sumxy = 0;
  my $sumy  = 0;
  my $sumy2 = 0;
  my $i     = 0;

  for ( $i = 0 ; $i <= $array_one_max_index ; $i++ )
  {
    $sumx  += $array_ref_one->[ $i ];
    $sumx2 += ( $array_ref_one->[ $i ] )**2;
    $sumxy += $array_ref_one->[ $i ] * $array_ref_two->[ $i ];
    $sumy  += $array_ref_two->[ $i ];
    $sumy2 += ( $array_ref_two->[ $i ] )**2;
  }
  my $m =
      ( ( $array_one_max_index + 1 ) * $sumxy - $sumx * $sumy ) /
      ( ( $array_one_max_index + 1 ) * $sumx2 - sqr( $sumx ) );
  my $b =
      ( $sumy * $sumx2 - $sumx * $sumxy ) /
      ( ( $array_one_max_index + 1 ) * $sumx2 - sqr( $sumx ) );
  my $r =
      ( $sumxy - $sumx * $sumy / ( $array_one_max_index + 1 ) ) /
      sqrt( ( $sumx2 - sqr( $sumx ) / ( $array_one_max_index + 1 ) ) *
            ( $sumy2 - sqr( $sumy ) / ( $array_one_max_index + 1 ) ) );

  return ( $m, $b, $r );

}

sub sqr
{
  $_[ 0 ] * $_[ 0 ];
}

# END regression subroutine

#*************************************************************#
#* stdev: Calculates the standard deviation of an array      *#
#* Input to function: array                                  *#
#* Returns to main: standard deviation                       *#
#*************************************************************#
sub stdev
{
  my $array_reference = shift;
  my $array_max_index = $#{$array_reference};

  if ( $array_max_index == -1 )
  {
    return 0;
  }
  my $array_sum_one = 0;
  my $array_sum_two = 0;
  my $i             = 0;

  for ( $i = 0 ; $i <= $array_max_index ; $i++ )
  {
    $array_sum_one += $array_reference->[ $i ]**2;
    $array_sum_two += $array_reference->[ $i ];
  }
  my $array_stdev =
      ( ( ( $array_max_index + 1 ) * $array_sum_one - ( $array_sum_two**2 ) ) /
        ( ( $array_max_index + 1 )**2 ) )**0.5;
  return $array_stdev;
}

# END stdev subroutine

#*************************************************************#
#* lsfderive: Calculates the derivative of a given array     *#
#* Input to function: array1, array2                         *#
#* Returns to main: derivative                               *#
#*************************************************************#
sub lsfderive
{

  my $order    = 1;
  my $shiftMax = 0;
  my @w        = ();

  my $xRef = shift;
  my $yRef = shift;

  # my $wRef = shift;

  my @x = @{$xRef};
  my @y = @{$yRef};

  # my @w = @{ $wRef };

  #print "X".Dumper(\@x)."\n";
  #print "Y".Dumper(\@y)."\n";
  #print "W".Dumper(\@w)."\n";

  # Run through data and find the best fit for 1 or more shifts
  my $windowSize = 10;
  my @firstDeriv = ();
  for ( my $i = 0 ; $i <= $#x - $windowSize ; $i++ )
  {
    my @tmpX = ( @x[ $i .. ( $i + $windowSize - 1 ) ] );
    my @tmpY = ( @y[ $i .. ( $i + $windowSize - 1 ) ] );
    my @tmpW = ( @w[ $i .. ( $i + $windowSize - 1 ) ] );
    my ( $coefRef, $sqErr ) = &runLSF( \@tmpX, \@tmpY, \@tmpW, $order );
    push @firstDeriv, $coefRef->[ 1 ];
  }

  $windowSize = 20;
  my @secDeriv = ();
  for ( my $i = 0 ; $i <= $#firstDeriv - $windowSize ; $i++ )
  {
    my @tmpX = ( @x[ $i ..          ( $i + $windowSize - 1 ) ] );
    my @tmpY = ( @firstDeriv[ $i .. ( $i + $windowSize - 1 ) ] );
    my @tmpW = ( @w[ $i ..          ( $i + $windowSize - 1 ) ] );
    my ( $coefRef, $sqErr ) = &runLSF( \@tmpX, \@tmpY, \@tmpW, $order );
    push @secDeriv, $coefRef->[ 1 ];

    #  print "$x[$i]  $coefRef->[1]\n";
  }

  return @secDeriv;

}

# END lsfderive subroutine

#*************************************************************#
#* runLSF: Calculates the derivative of a given array        *#
#* Input to function: array1, array2                         *#
#* Returns to main: derivative                               *#
#*************************************************************#

sub runLSF
{
  my $xRef      = shift;
  my $yRef      = shift;
  my $wRef      = shift;
  my $order     = shift;
  my $dataShift = shift;

  my @x = @{$xRef};
  my @y = @{$yRef};
  my @w = @{$wRef};

  if ( $dataShift )
  {
    if ( $dataShift > 0 )
    {
      # shift forward
      #   cut off begining of x
      #   cut off end of y
      splice( @x, 0, $dataShift );
      splice( @y, $#y - $dataShift + 1, $dataShift );
    } else
    {
      # shift backward
      #   cut off begining of y
      #   cut off end of x
      splice( @y, 0, abs( $dataShift ) );
      splice( @x, $#x - abs( $dataShift ) + 1, abs( $dataShift ) );
    }
  }

  my @s_xn;
  my @s_yxn;
  my @s_xn;
  for ( my $i = 0 ; $i <= $#x ; $i++ )
  {
    my $j;
    my $x = $x[ $i ];
    my $y = $y[ $i ];
    my $w = $w[ $i ];

    # Save Sum(X**n) and Sum(Y * X**n)
    # Weight data point if desired
    my $xn = 1;
    #####$xn = $w if ( $options{'w'} );
    for ( $j = 0 ; $j <= $order ; $j++, $xn *= $x )
    {
      $s_xn[ $j ]  += $xn;
      $s_yxn[ $j ] += $xn * $y;
    }
    for ( ; $j <= 2 * $order ; $j++, $xn *= $x )
    {
      $s_xn[ $j ] += $xn;
    }
  }

  # Load the matrix.
  my %matrix;
  for ( my $i = 0 ; $i <= $order ; $i++ )
  {
    for ( my $j = 0 ; $j <= $order ; $j++ )
    {
      $matrix{ $i, $j } = $s_xn[ $i + $j ];
    }
  }

  my @coefficient = &solve_matrix_eq( \%matrix, \@s_yxn );

  #for( my $i = 0; $i <= $order; $i++)
  #{
  #  printf "A%d = %.6e\n",$i,$coefficient[$i];
  #}

  my $sqErr = 0;
  for ( my $i = 0 ; $i <= $#x ; $i++ )
  {
    my $y1 = &calc( $x[ $i ], \@coefficient );
    $sqErr += abs( $y1 - $y[ $i ] ) * abs( $y1 - $y[ $i ] );
  }

  #print "\nSum Squares Error = $sqErr for shift = $dataShift\n";

  #####if($options{'c'})
  #####{
  #####printf "\n%12s %12s %12s %12s\n","x","y","y fit","fit error";

  #####for(my $i = 0; $i <= $#x; $i++)
  #####{
  #####my $y1 = &calc($x[$i], \@coefficient);
  #####printf "%12.2g %12.2g %12.2g %12.2g\n", $x[$i],$y[$i],$y1,$y1-$y[$i];
  #####}
  #####}
  return ( \@coefficient, $sqErr );
}

# END runLSF subroutine

##### Polynomial fitting routines

sub solve_matrix_eq    # pass *matrix and *vector
{                      # returns @x solution of [matrix]*[@x]=[vector]
  my $matrixRef = shift;
  my $vectorRef = shift;
  my %mat       = %{$matrixRef};
  my $size      = $#{$vectorRef} + 1;
  my ( $i, $j, $k, $f );

  # NOTE: This is highly optimized form of a hash initialization
  @mat{ grep( $_ .= "$;$size", ( 0 .. $#{$vectorRef} ) ) } = @{$vectorRef};

  for ( $i = 0 ; $i < $#{$vectorRef} ; $i++ )
  {
    for ( $j = $i + 1 ; $j <= $#{$vectorRef} ; $j++ )
    {
      $f = $mat{ $i, $i } / $mat{ $j, $i };
      for ( $k = 0 ; $k <= $size ; $k++ )
      {
        $mat{ $j, $k } = $mat{ $j, $k } * $f - $mat{ $i, $k };
      }
    }
  }
  for ( $i = $#{$vectorRef} ; $i > 0 ; $i-- )
  {
    for ( $j = $i - 1 ; $j >= 0 ; $j-- )
    {
      $f = $mat{ $i, $i } / $mat{ $j, $i };
      for ( $k = $j ; $k <= $size ; $k++ )
      {
        $mat{ $j, $k } = $mat{ $j, $k } * $f - $mat{ $i, $k };
      }
    }
  }

  # Normalize the diagonal
  for ( $i = 0 ; $i <= $#{$vectorRef} ; $i++ )
  {
    $mat{ $i, $size } /= $mat{ $i, $i };
    $mat{ $i, $i } = 1.0;
  }

  # Answer is in augmented column
  @mat{ grep( $_ .= "$;$size", ( 0 .. $#{$vectorRef} ) ) };
}

sub calc    # Pass $x and *a (array of coefficients)
{           # Returns Sum($a[$i] * $x**$i)
  my $x        = shift;
  my $arrayRef = shift;
  my ( $y, $xn );

  $xn = 1;
  foreach my $val ( @{$arrayRef} )
  {
    $y += $val * $xn;
    $xn *= $x;
  }
  return ( $y );
}

1;
