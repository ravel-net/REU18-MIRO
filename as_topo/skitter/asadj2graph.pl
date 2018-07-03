#!/usr/bin/env perl
#
##########################################################################
## Copyright 2004
## The Regents of the University of California
## All Rights Reserved
##
## Permission to use, copy, modify and distribute any part of
## this software package for educational, research and non-profit
## purposes, without fee, and without a written agreement is hereby
## granted, provided that the above copyright notice, this paragraph
## and the following paragraphs appear in all copies.
##
## Those desiring to incorporate this into commercial products or
## use for commercial purposes should contact the Technology Transfer
## Office, University of California, San Diego, 9500 Gilman Drive,
## La Jolla, CA 92093-0910, Ph: (858) 534-5815, FAX: (858) 534-7345.
##
## IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
## PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
## DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS
## SOFTWARE, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED
## OF THE POSSIBILITY OF SUCH DAMAGE.
##
## THE SOFTWARE PROVIDED HEREIN IS ON AN "AS IS" BASIS, AND THE
## UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE,
## SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. THE UNIVERSITY
## OF CALIFORNIA MAKES NO REPRESENTATIONS AND EXTENDS NO WARRANTIES
## OF ANY KIND, EITHER IMPLIED OR EXPRESS, INCLUDING, BUT NOT LIMITED
## TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A
## PARTICULAR PURPOSE, OR THAT THE USE OF THE SOFTWARE WILL NOT
## INFRINGE ANY PATENT, TRADEMARK OR OTHER RIGHTS.
##
## This software package is developed by the CAIDA development team
## at the University of California, San Diego under the Cooperative
## Association for Internet Data Analysis (CAIDA) Program. Support
## for this effort is provided by the NSF grant ANI-0221172 and by
## CAIDA members.
##
## Report bugs and suggestions to info@caida.org.
##
## Written by Dmitri Krioukov <dima@caida.org> 05/26/04
##
##########################################################################
##########################################################################
#
#  DESCRIPTION:
#              filter AS adjacency files into AS graph adjacency matrices
#
#  INPUT:
#              AS adjacency files:
#              http://www.caida.org/tools/measurement/skitter/as_adjacencies.xml
#
#  OUTPUT:
#              AS graph adjacency matrices in the following format: line
#                 AS_X   AS_Y
#              represents a link between AS_X and AS_Y
#
##########################################################################

use strict;
use warnings;
use Getopt::Std;
our %opts;
my $input_dir   = ".";
my $input_file  = "skitter_as_links.*.gz";
my $output_dir  = ".";
my $output_file = "skitter_as_graph";
my $start_date  = 00000000;
my $end_date    = 99999999;
my %graph;

sub PrintUsage {
  print " usage: $0 {-d|-i length} [-smpnou] [-l input] [-g output] [-r dates]\n";
  print "  -d:  include direct links\n";
  print "  -i:  include indirect links of maximum 'length'\n";
  print "         'length' = -1 to include all indirect links\n";
  print "  -s:  include links to/from AS-sets\n";
  print "  -m:  include links to/from MOASs\n";
  print "  -p:  include private ASs\n";
  print "  -o:  output = stdout (and input = stdin if no '-u' option)\n";
  print "  -l:  search for link files named $input_file\n";
  print "         below 'input' directory\n";
  print "  -g:  place output files in 'output' directory\n";
  print "  -u:  merge links in all input files into one 'output' file\n";
  print "  -n:  neglect direction in the input files, produce undirected graphs\n";
  print "  -r:  inclusive range of 'dates' of input files\n";
  print "         'dates' must be YYYYMMDD:yyyymmdd (start date:end date)\n";
  return 1;
}

if (!getopts("di:smpuonl:g:r:", \%opts)
     or (!defined $opts{'d'} and !defined $opts{'i'})
     or (defined $opts{'i'} and !($opts{'i'} =~ /[-]*\d+/))
     or (defined $opts{'r'} and !($opts{'r'} =~ /\d{8}:\d{8}/))
   ) {
  exit PrintUsage();
}

if (defined $opts{'o'} and !defined $opts{'u'}) { # standard input/output
  MergeGraph(\*STDIN, \%graph);
  PrintGraph(\*STDOUT, \%graph);
  exit 0;
}

if (defined $opts{'l'}) { # input directory
  $input_dir = $opts{'l'};
}

if (defined $opts{'g'}) { # output directory
  $output_dir = $opts{'g'};
}
if (! -e $output_dir) {
  mkdir $output_dir;
}
elsif (! -d $output_dir) {
  die("$output_dir exists and is not a directory");
}
if (!($output_dir =~ /\/$/)) {
  $output_dir .= '/';
}

if (defined $opts{'r'}) { # range of dates
  ($start_date, $end_date) = split /:/, $opts{'r'};
}

if (defined $opts{'i'}) {
  $output_file .= ".indirect:$opts{'i'}";
}
if (defined $opts{'m'}) {
  $output_file .= ".moass";
}
if (defined $opts{'s'}) {
  $output_file .= ".assets";
}
if (defined $opts{'p'}) {
  $output_file .= ".private";
}
if (defined $opts{'n'}) {
  $output_file .= ".undirected";
}
else {
  $output_file .= ".directed";
}
if (defined $opts{'u'}) {
  $output_file .= ".merge";
  if (defined $opts{'r'}) {
    $output_file .= ".dates:$start_date-$end_date"
  }
}

my %date_files = GetFiles($input_dir, $input_file);

if (defined $opts{'u'}) { # merge links from all input files

  foreach my $date (reverse sort {$a<=>$b} keys %date_files) {
    next if ($date < $start_date or $date > $end_date);
    my $input = $date_files{$date};
    open(IN, "gunzip -c $input |") || die("unable to open \"$input\"");
    MergeGraph(\*IN, \%graph);
    close(IN);
  }

  if (!defined $opts{'o'}) { # print to a file
    my $output = $output_dir . $output_file . ".gz";
    open(OUT, "| gzip -c >$output") || die("unable to open \"$output\"");
    PrintGraph(\*OUT, \%graph);
    close(OUT);
  }
  else {
    PrintGraph(\*STDOUT, \%graph);
  }

  exit 0;
}

# print file-by-file
foreach my $date (reverse sort {$a<=>$b} keys %date_files) {
  next if ($date < $start_date or $date > $end_date);
  my $input = $date_files{$date};
  my $output = $output_dir . $output_file . "." . $date . ".gz";
  open(IN, "gunzip -c $input |") || die("unable to open \"$input\"");
  open(OUT, "| gzip -c >$output") || die("unable to open \"$output\"");
  undef %graph;
  MergeGraph(\*IN, \%graph);
  PrintGraph(\*OUT, \%graph);
  close(IN);
  close(OUT);
}
exit 0;

# search for input files
sub GetFiles {
  my ($dir, $file_pattern) = @_;
  my %date2file;
  foreach my $file (`find $dir -name '$file_pattern'`) {
    if ($file =~ /(\d{8})/) {
      my $date = $1;
      $date2file{$date} = $file;
    }
  }
  return %date2file;
}

# merge links from file into the graph
sub MergeGraph {
  my ($input_fh, $graph) = @_;
  while (<$input_fh>) { # actual filtering
    s/#.*//;
    next if (/^\s*$/ or /null/);
    next if (!defined $opts{'s'} and (/,/ or /\{/ or /\}/)); # AS-sets
    next if (!defined $opts{'m'} and /_/); # MOASs
    if ( ( (defined $opts{'d'} and /^D\s+(\S+)\s+(\S+)/) # direct links
           or
           (defined $opts{'i'} and /^I\s+(\S+)\s+(\S+)\s+(\d+)/
             and ($opts{'i'} < 0 or $3 <= $opts{'i'})
           ) # indirect links
         )
         and ($1 ne $2) # filter links from a node to itself
       ) {
      my ($from, $to) = ($1, $2); # ($1, $2) is a link from $1 to $2
      # private ASs:
      next if (!defined $opts{'p'} and ContainsPrivateAS($from, $to));
      if (defined $opts{'n'}) { # neglect direction
	($from, $to) = sort MixedSort ($from, $to);
      }
      $graph->{$from}{$to} = 1;
    }
  }
  return 0;
}

# check for private AS numbers in strings
sub ContainsPrivateAS {
  my @strings = @_;
  foreach my $string (@strings) {
    foreach my $number (split /\D+/, $string) {
      return 1 if ($number > 64511);
    }
  }
  return 0;
}

# print graph with MOASs and AS-sets sorted down
sub PrintGraph {
  my ($output_fh, $graph) = @_;
  foreach my $from (sort MixedSort keys %$graph) {
    foreach my $to (sort MixedSort keys %{$graph->{$from}}) {
      print $output_fh "$from\t$to\n";
    }
  }
  return 0;
}

sub MixedSort {
  return ($a cmp $b) if ( ($a =~ /\D/) and  ($b =~ /\D/) );
  return ($a <=> $b) if (!($a =~ /\D/) and !($b =~ /\D/) );
  return      1      if ( ($a =~ /\D/) and !($b =~ /\D/) );
  return      -1     if (!($a =~ /\D/) and  ($b =~ /\D/) );
}
