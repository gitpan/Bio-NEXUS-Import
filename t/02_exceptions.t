#!/usr/bin/perl -T
# Written by Markus Riester (mriester@gmx.de)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 6th July 2007
use strict;
use warnings;

use Test::More tests => 8;
#use Test::More 'no_plan';
use Data::Dumper;

use Bio::NEXUS::Import;
use English qw( -no_match_vars );


### first testfile

my $nexus;

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/01_distances_square.phy');
};    

ok(!$EVAL_ERROR, 'No exception with valid phylip file') || diag $EVAL_ERROR;

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/notexistingfile.phy');
};    

ok($EVAL_ERROR, 'Exception with not exisiting file');
diag("\nYOU SHOULD SEE AN EXCEPTION:\n $EVAL_ERROR\n END OF EXCEPTION\n");

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/01_distances_square.phy',
        'PHYLIP_DIST_SQUARE');
};    

ok(!$EVAL_ERROR, 'No exception with valid phylip file and correct format') || diag $EVAL_ERROR;

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/01_distances_square.phy',
        'PHYLIP_UNSUPPORTED_FORMAT');
};    

ok($EVAL_ERROR, 'Exception with valid phylip file and wrong format') || diag $EVAL_ERROR;
diag("\nYOU SHOULD SEE AN EXCEPTION:\n $EVAL_ERROR\n END OF EXCEPTION\n");

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/01_seqs_interleaved.phy');
};    

ok(!$EVAL_ERROR, 'No exception with valid phylip file and correct format') || diag $EVAL_ERROR;

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/01_seqs_interleaved.phy',
        'PHYLIP_DIST_SQUARE');
};    

ok($EVAL_ERROR, 'Exception with valid phylip file and wrong format') || diag $EVAL_ERROR;
diag("\nYOU SHOULD SEE AN EXCEPTION:\n $EVAL_ERROR\n END OF EXCEPTION\n");

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/02_wrong_distances.phy',
        'PHYLIP_DIST_SQUARE');
};    

ok($EVAL_ERROR, 'Exception with valid phylip file and wrong format') || diag $EVAL_ERROR;
diag("\nYOU SHOULD SEE AN EXCEPTION:\n $EVAL_ERROR\n END OF EXCEPTION\n");

eval {
    $nexus = Bio::NEXUS::Import->new('t/data/02_strangefile.dat');
};    

ok($EVAL_ERROR, 'Exception with invalid phylip file and undefined format') || diag $EVAL_ERROR;
diag("\nYOU SHOULD SEE AN EXCEPTION:\n $EVAL_ERROR\n END OF EXCEPTION\n");
