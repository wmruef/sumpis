#!/usr/bin/perl
use Test::More;

#
# Testing comparison to Seabird conversion software using
# an unaligned conversion.
#
print "\nTesting SBE19Plus SUMPIS conversion vs Seabird SBE Data Processing\n";
unlink "run_1.out" if ( -e "run_1.out" );
my $cmd = "../sumpis.pl -no_align -format 19Plus_compare " .
          "-caldir raw " .
          "-config ../configurationFiles/TORCA_conf.txt " .
          "raw/201601 >> run_1.out";

system($cmd);
system("mv raw/201601/*.HTA processed_compare/201601/");

opendir DIR,"processed_compare/201601/" or die;
while ( my $entry = readdir(DIR) )
{
  if ( $entry =~ /(.*)\.HTA/ )
  {
    # ORCA1_CAST28921deriveONLY.cnv 
    my $seabird_equiv_file = "$1deriveONLY.cnv";
    my $result = `./cnvdiff.pl processed_seabird_noalign/$seabird_equiv_file processed_compare/201601/$entry`;
    ok ( $result =~ /^\s*$/,  "Unaligned comparison to seabird conversion for $entry" ) or
      diag( "Try running: ./cnvdiff.pl processed_seabird_noalign/$seabird_equiv_file processed_compare/201601/$entry\nAnd check run_1.out for errors!" );
  }
}
close DIR;

#
#
#
print "\nTesting SBE19 SUMPIS conversion vs Seabird SBE Data Processing\n";
unlink "run_1a.out" if ( -e "run_1a.out" );
my $cmd = "../sumpis.pl -no_align -format 19_compare " .
          "-caldir raw " .
          "-config ../configurationFiles/TORCA_conf.txt " .
          "raw/200501 >> run_1a.out";

system($cmd);
system("mv raw/200501/*.HTA processed_compare/200501/");

opendir DIR,"processed_compare/200501/" or die;
while ( my $entry = readdir(DIR) )
{
  if ( $entry =~ /(.*)\.HTA/ )
  {
    # ORCA1_CAST28921deriveONLY.cnv 
    my $seabird_equiv_file = "$1.cnv";
    my $result = `./cnvdiff.pl processed_seabird_noalign/$seabird_equiv_file processed_compare/200501/$entry`;
    ok ( $result =~ /^\s*$/,  "Unaligned comparison to seabird conversion for $entry" ) or
      diag( "Try running: ./cnvdiff.pl processed_seabird_noalign/$seabird_equiv_file processed_compare/200501/$entry\nAnd check run_1a.out for errors!" );
  }
}
close DIR;


#
# Compare with previous Sumpis conversion runs to sanity check for
# result changes.
#
# Aligned data
print "\nTesting aligned SBE19Plus SUMPIS conversion vs verified SUMPIS conversions\n";
unlink "run_2.out" if ( -e "run_2.out" );
my $cmd = "../sumpis.pl -format default " .
          "-caldir raw " .
          "-config ../configurationFiles/TORCA_conf.txt " .
          "raw/201601 >> run_2.out";

system($cmd);
system("mv raw/201601/*.DGC processed/aligned/201601/");

opendir DIR,"processed/aligned/201601/" or die;
while ( my $entry = readdir(DIR) )
{
  if ( $entry =~ /(.*)\.DGC/ )
  {
    my $result = `diff verified/aligned/201601/$entry processed/aligned/201601/$entry`;
    ok ( $result =~ /^\s*$/,  "Comparison to previous Sumpis conversion for $entry" ) or
      diag( "Try running: diff verified/aligned/201601/$entry processed/aligned/201601/$entry\nAnd check run_2.out for errors!" );
  }
}
close DIR;

# Unaligned data
print "\nTesting unaligned SBE19Plus SUMPIS conversion vs verified SUMPIS conversions\n";
unlink "run_3.out" if ( -e "run_3.out" );
my $cmd = "../sumpis.pl -no_align -format default " .
          "-caldir raw " .
          "-config ../configurationFiles/TORCA_conf.txt " .
          "raw/201601 >> run_3.out";

system($cmd);
system("mv raw/201601/*.DGC processed/unaligned/201601/");

opendir DIR,"processed/unaligned/201601/" or die;
while ( my $entry = readdir(DIR) )
{
  if ( $entry =~ /(.*)\.DGC/ )
  {
    my $result = `diff verified/unaligned/201601/$entry processed/unaligned/201601/$entry`;
    ok ( $result =~ /^\s*$/,  "Comparison to previous Sumpis conversion for $entry" ) or
      diag( "Try running: diff verified/unaligned/201601/$entry processed/unaligned/201601/$entry\nAnd check run_3.out for errors!" );
  }
}
close DIR;


#
# Declare ourselves done to perl module Test::More
#
done_testing();

1;
