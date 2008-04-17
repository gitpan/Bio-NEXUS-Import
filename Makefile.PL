use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::NEXUS::Import',
    AUTHOR              => 'Markus Riester <mriester@gmx.de>',
    VERSION_FROM        => 'lib/Bio/NEXUS/Import.pm',
    ABSTRACT_FROM       => 'lib/Bio/NEXUS/Import.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Bio::NEXUS'    => 0.67,
    },
    EXE_FILES           => [ 
                  'bin/phylip2nex.pl',
                           ],

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-NEXUS-Import-*' },
);
