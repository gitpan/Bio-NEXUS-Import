#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage; 
use Bio::NEXUS::Import;
use Data::Dumper;

my $nexus = new Bio::NEXUS::Import;
my $version = $nexus::VERSION;

  #################
 # cmd line args #
#################
my (%opts);
Getopt::Long::Configure("bundling"); # for short options bundling
GetOptions( \%opts, 
            'format|f=s', 
            'outfile|o=s', 
            'verbose|v', 
            'version|V', 
            'man', 
            'help|h',
          ) or pod2usage(2);

if ( $opts{ 'version' } ) { die "Version$version\n"; } 
pod2usage( -exitval => 0, verbose => 2 ) if $opts{ man };
pod2usage( 1 ) if !@ARGV or $opts{ help };

my ($infile,$outfile,$inputFormat,$verbose);
$infile = shift or die "specify infile as last argument on commandline"; 
$outfile = ( $opts{ 'outfile' } ? $opts{ 'outfile' } : 'out.nex' ); 
$inputFormat = ( $opts{ 'format' } ? $opts{ 'format' } : undef ); 
$verbose = ( $opts{ 'verbose' } ? 1 : 0 ); 


$nexus->import_file($infile, $inputFormat, $verbose);
$nexus->write($outfile);

1;


=head1 NAME

phylip2nex.pl - convert a PHYLIP file into NEXUS format 

=head1 VERSION

This document describes phylip2nex.pl version 0.0.2

=head1 SYNOPSIS

phylip2nex.pl [options] <infile> 

=head1 DESCRIPTION

Outputs the PHYLIP file in <infile> in NEXUS format.   

=head1 OPTIONS

=over 8

=item B<-f, --format> 

The format of the input file.  See L<Bio::NEXUS::Import> for a list of
supported file formats. If no format is specified, then L<Bio::NEXUS::Import> 
will try to guess the correct format.

=item B<-o, --outfile> 

The name of the output file.  Defaults to out.nex. 

=item B<-h, --help> 

Print a brief help message and exits.

=item B<--man> 

Print the manual page and exits.

=item B<-V, --version> 

Print the version information and exit.

=back

=head1 SEE ALSO

L<Bio::NEXUS::Import>

=head1 AUTHOR

Markus Riester (mriester@gmx.de)

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
