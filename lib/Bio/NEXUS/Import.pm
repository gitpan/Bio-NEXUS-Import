package Bio::NEXUS::Import;

use warnings;
use strict;
use Carp;

use Bio::NEXUS;
use Bio::NEXUS::Functions;

use base 'Bio::NEXUS';

use version; our $VERSION = qv('0.0.1');


sub new {
    my ( $class, $filename, $fileformat, $verbose ) = @_;
    my $self = {};
    bless( $self, $class );
    $self->{'supported_file_formats'} = {
        'phylip' => { 
            'PHYLIP_DIST_SQUARE'     => 1,
            'PHYLIP_DIST_LOWER'      => 1,
            'PHYLIP_DIST_UPPER'      => 1,
            'PHYLIP_SEQ_INTERLEAVED' => 1,
            'PHYLIP_SEQ_SEQUENTIAL'  => 1,
        },
        'nexus' => { 'NEXUS' => 1 },
    };    
    if (defined $filename) {
        $self->import_file( $filename, $fileformat, $verbose );
        $self->set_name($filename);
    }
    return $self;
}
    

sub import_file {
    my ( $self, $filename, $fileformat, $verbose ) = @_;
    croak "ERROR: $filename is not a valid filename\n" unless -e $filename;
    my @filecontent = split "\n", $self->_load_file( {
            'format' => 'filename', 'param' => $filename, 'verbose' => $verbose,
        });
    if (!defined $fileformat) {
        print "Trying to detect format of $self->{filename}.\n"
            if $verbose;
        $fileformat = $self->_detect_fileformat(\@filecontent);
        print "$fileformat detected.\n" if $verbose;
    }
    my $sff = $self->{'supported_file_formats'};
    if (defined $sff->{'phylip'}->{$fileformat}) {
        $self->_import_phylip( { 
            'filecontent' => \@filecontent, 'param' => $filename, 'verbose' => $verbose,
            'fileformat' => $fileformat,
          }
        );
    }
    elsif (defined $sff->{'nexus'}->{$fileformat}) {
        $self->read_file($filename, $verbose);
    }    
    else {
        croak "ERROR: $fileformat is not supported.\n";
    }    
}

sub _detect_fileformat {
    my ( $self, $filecontent ) = @_;
    if ($filecontent->[0] =~ m{\A \s* (\d+)\s+(\d+) \s* \z}xms) {
        if ($filecontent->[2] =~ m{\A [\sAGCTU]+ \z }xmsi) {
            return 'PHYLIP_SEQ_SEQUENTIAL';
        }    
        else {
            return 'PHYLIP_SEQ_INTERLEAVED';
        }
    }    
    elsif ($filecontent->[0] =~ m{\A \s* (\d+) \s* \z}xms) {
        my $number_taxa = $1;
        if (length $filecontent->[1] <= 10) {
            return 'PHYLIP_DIST_LOWER';
        }    
        else {
            return 'PHYLIP_DIST_SQUARE';
        }    
    }
    elsif ($filecontent->[0] =~ m{\A \s* \#NEXUS \s* \z}xms) {
        return 'NEXUS';
    }    
    else {
        croak("ERROR: Could not detect file format.\n");
    }    
}   

sub _load_file {
    my ( $self, $args ) = @_;
    $args->{'format'} ||= 'string';
    $args->{'param'}  ||= '';
    my $verbose = $args->{'verbose'} || 0;
    my $file;
    my $filename;

    if ( lc $args->{'format'} eq 'string' ) {
        $file = $args->{'param'};
    }
    else {
        $filename   = $args->{'param'};
        $file = _slurp($filename);
    }

    # Read entire file into scalar $import_file
    print("Reading file...\n") if $verbose;
    $self->{'filename'} = $filename;
    return $file;
}

sub _import_phylip {
    my ( $self, $args ) = @_;
    
    my $filename = $self->{'filename'};

    $args->{'fileformat'} ||= '_dist_square';
    my $ff = $args->{'fileformat'}; 
    $ff = lc $ff;
    my $verbose = $args->{'verbose'} || 0;
    my $line_number = 0;
    my $taxon_started = 0;
    my $number_taxa;
    my $number_chars;
    my @taxdata;
    my @taxlabels;
    my $taxon_id = -1;
    LINE:
    for my $line ( @{ $args->{'filecontent'}} ) {
        $line_number++;

        #remove newline, leading and trailing whitespaces
        chomp $line;
        $line  =~ s{\A \s+}{}xms;
        $line  =~ s{\s+ \z}{}xms;

        next LINE if $line eq '';

        if ($line_number == 1) {
            
            if ($ff =~ /dist/) {
                ( $number_taxa )  = $line =~ m{\A \s* (\d+) \s* \z}xms;
            }    
            else {
                # sequence data has the number of characters in the first line
                ( $number_taxa, $number_chars )  = $line =~ m{\A \s* (\d+)\s+(\d+) \s* \z}xms;
                if (!defined $number_chars) {
                    croak(
"Could not import $filename: first line must contain number of characters.\n"
                        );
                }    
            }    
            if (!defined $number_taxa) {
                croak(
"Could not import $filename: first line must contain number of taxa.\n"
                     );
            }    
            next LINE;
        }    
        if (!$taxon_started) {
            $taxon_id++;
            # first 10 chars are the labels
            my ($label, $data) = $line =~ m{ \A (.{10})(.*) \z }xms;
            
            # undefined? then we have only one label, no data
            # for example in the first row of a lower distmatrix
            if (!defined $label) {
                $label = $line;
                $data  = '';
            }    

            #remove leading and trailing whitespaces
            $data  =~ s{\A \s+}{}xms;
            $label =~ s{\s+ \z}{}xms;
            my @taxondata = split /\s+/, $data;
                
            $taxdata[$taxon_id] = [ @taxondata ] ;
            push @taxlabels, $label;
        }
        else {
            my @taxondata = @{$taxdata[$taxon_id]};
            push @taxondata, split(/\s+/, $line);
            $taxdata[$taxon_id] = [ @taxondata ];
        }

        if ( $ff =~ /dist/ ) {

            # how many tab/space seperated items do we expect?
            my $number_items_in_row;
            if ($ff =~ /_dist_square/) {
                $number_items_in_row = $number_taxa;
            }    
            elsif ($ff =~ /_dist_lower/) {
                $number_items_in_row = $taxon_id;
            }    
            elsif ($ff =~ /_dist_upper/) {
                $number_items_in_row = $number_taxa -($taxon_id+1);
            }

            if (scalar(@{$taxdata[$taxon_id]}) < $number_items_in_row) {
                $taxon_started = 1;
            }
            else {
                $taxon_started = 0;
            }  
        }
        else {
            my $seq = join '', @{$taxdata[$taxon_id]};
            if ($ff =~ /_seq_seq/) { 
                if (length($seq) < $number_chars) {
                    $taxon_started = 1;
                }
                else {
                    $taxon_started = 0;
                }    
            }

            next LINE if $ff =~ /_seq_seq/;
            # interleaved
            if (scalar(@taxlabels) == $number_taxa) {
                if ($taxon_id >= ($number_taxa - 1)) {
                    $taxon_id = 0;
                } else {    
                    $taxon_id++;
                }    
                $taxon_started = 1;
            }
        }    
    }
    croak "ERROR: Could not parse $filename. Number taxa not correct.\n" if
        scalar(@taxlabels) != $number_taxa;
    my $taxa_block = new Bio::NEXUS::TaxaBlock('taxa');
    $taxa_block->set_taxlabels(\@taxlabels);
    $self->add_block($taxa_block);
   
    if ( $ff =~ /dist/ ) {
        my $distances_block = new Bio::NEXUS::DistancesBlock('distances');
        $distances_block->set_ntax( scalar(@taxlabels) );
        $distances_block->set_taxlabels(  \@taxlabels );
        $distances_block->set_format({triangle   =>'lower', diagonal => 1, labels => 1});
        my $matrix;
        for my $i ( 0 .. $distances_block->get_ntax-1 ) {
            for my $j ( 0 .. $distances_block->get_ntax-1 ) {
                my $dist;
                if (defined $taxdata[$i]->[$j]) {
                $dist = $taxdata[$i]->[$j]
                }   
                else {
                    $dist = $taxdata[$j]->[$i];
                    # diag. entries:
                    if (!defined $dist) {
                        $dist = 0;
                    } 
                }    
                $matrix->{$taxlabels[$i]}{$taxlabels[$j]} = $dist;
            }    
        }    
        $distances_block->{matrix} = $matrix;
#        $distances_block->_write_matrix();
        
        $self->add_block($distances_block);
    }
    else {
        my $chars_block = new Bio::NEXUS::CharactersBlock('characters');
        my %taxa;
        for my $i ( 0 .. $number_taxa-1 ) {
            $taxa{$taxlabels[$i]} = join('', @{$taxdata[$i]});
        }    

        my (@otus);
        
        for my $name (@taxlabels) {
            my $seq = $taxa{$name};
            push @otus, Bio::NEXUS::TaxUnit->new( $name, [ split //, $seq ] );
        }

        my $otuset = $chars_block->get_otuset();
        $otuset->set_otus( \@otus );
        $chars_block->set_taxlabels( $otuset->get_otu_names() );
        
        $self->add_block($chars_block);
    }    
    print "File import complete.\n"  if $verbose;
    return $self;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Bio::NEXUS::Import - Extends Bio::NEXUS with parsers for file formats of
popular phylogeny programs


=head1 VERSION

This document describes Bio::NEXUS::Import version 0.0.1


=head1 SYNOPSIS

    use Bio::NEXUS::Import;

    # a PHYLIP-TO-NEXUS converter:
    #
    # load a PHYLIP file
    my $nexus = Bio::NEXUS::Import->new('example.phy');
    
    # and write it as NEXUS formatted file
    $nexus->write('example.nex');

=head1 DESCRIPTION

A module that extends L<Bio::NEXUS> with parsers for file formats of popular 
phylogeny programs.

=head1 INTERFACE 

=head2 new

 Title   : new
 Usage   : Bio::NEXUS::Import->new($filename, $fileformat, $verbose);
 Function: If $filename is defined, then this function calls import_file 
 Returns : an Bio::NEXUS object
 Args    : $filename, $fileformat, $verbose, or none
 See also: import_file for a list of supported fileformats, for examples see
           APPENDIX: SUPPORTED FILE FORMATS.


=head2 import_file

 Title   : import_file
 Usage   : Bio::NEXUS::Import->import_file($filename, $fileformat, $verbose);
 Function: Reads the contents of the specified file and populate the data 
           in the Bio::NEXUS object.
           Supported fileformats are NEXUS, PHYLIP_DIST_SQUARE, PHYLIP_DIST_LOWER,
           PHYLIP_SEQ_INTERLEAVED, PHYLIP_SEQ_SEQUENTIAL.
           If $fileformat is not defined, then this function tries to
           detect the correct format. NEXUS files are parsed with
           Bio::NEXUS->read_file();
 Returns : None
 Args    : $filename,  optional: $fileformat, $verbose. 


=head1 DIAGNOSTICS


=over

=item C<< ERROR: $filename is not a valid filename. >>

The file you have specified in L</"new"> or L</"import_file"> does not exist.

=item C<< ERROR: $fileformat is not supported. >>

The fileformat you have specified in L</"new"> or L</"import_file"> is not supported.
See L<"APPENDIX: SUPPORTED FILE FORMATS"> for a list of supported formats.

=item C<< Could not import $filename: first line must contain number of taxa. >>

You tried to import a file with the PHYLIP parser but the file does not look like a 
PHYLIP file. See L<"APPENDIX: SUPPORTED FILE FORMATS"> for valid PHYLIP files.

=item C<< Could not import $filename: first line must contain number of characters. >>

You tried to import a file with the PHYLIP parser for sequence data but the file does
not look like a PHYLIP file. See L<"APPENDIX: SUPPORTED FILE FORMATS"> for valid PHYLIP files.

=item C<< ERROR: Could not parse $filename. Number taxa not correct. >> 

There are taxa in the PHYLIP file than specified in the header. Check your input file.


=item C<< ERROR: Could not detect file format. >>

You haven't specified a file format and Bio::NEXUS::Import could not detect
the format of your file.


=back


=head1 CONFIGURATION AND ENVIRONMENT

Bio::NEXUS::Import requires no configuration files or environment variables.


=head1 DEPENDENCIES


L<Bio::NEXUS> 


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bio-nexus-import@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 APPENDIX: SUPPORTED FILE FORMATS

Below a collection of examples of all supported file formats:

=over

=item C<PHYLIP_DIST_SQUARE>


        5
    Alpha      0.000 1.000 2.000 3.000 3.000
    Beta       1.000 0.000 2.000 3.000 3.000
    Gamma      2.000 2.000 0.000 3.000 3.000
    Delta      3.000 3.000 0.000 0.000 1.000
    Epsilon    3.000 3.000 3.000 1.000 0.000

=item C<PHYLIP_DIST_LOWER>


        5
    Alpha      
    Beta       1.00
    Gamma      3.00 3.00
    Delta      3.00 3.00 2.00
    Epsilon    3.00 3.00 2.00 1.00


=item C<PHYLIP_SEQ_INTERLEAVED>


    5    42
    Turkey    AAGCTNGGGC ATTTCAGGGT
    Salmo gairAAGCCTTGGC AGTGCAGGGT
    H. SapiensACCGGTTGGC CGTTCAGGGT
    Chimp     AAACCCTTGC CGTTACGCTT
    Gorilla   AAACCCTTGC CGGTACGCTT

    GAGCCCGGGC AATACAGGGT AT
    GAGCCGTGGC CGGGCACGGT AT
    ACAGGTTGGC CGTTCAGGGT AA
    AAACCGAGGC CGGGACACTC AT
    AAACCATTGC CGGTACGCTT AA

=item C<PHYLIP_SEQ_SEQUENTIAL>


    5    42
    Turkey    AAGCTNGGGC ATTTCAGGGT
    GAGCCCGGGC AATACAGGGT AT
    Salmo gairAAGCCTTGGC AGTGCAGGGT
    GAGCCGTGGC CGGGCACGGT AT
    H. SapiensACCGGTTGGC CGTTCAGGGT
    ACAGGTTGGC CGTTCAGGGT AA
    Chimp     AAACCCTTGC CGTTACGCTT
    AAACCGAGGC CGGGACACTC AT
    Gorilla   AAACCCTTGC CGGTACGCTT
    AAACCATTGC CGGTACGCTT AA

=back

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Markus Riester C<< <mriester@gmx.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
