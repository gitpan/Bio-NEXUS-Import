use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::NEXUS::Import',
    license             => 'perl',
    dist_author         => 'Markus Riester <mriester@gmx.de>',
    dist_version_from   => 'lib/Bio/NEXUS/Import.pm',
    requires => {
        'version'    => 0,
        'Bio::NEXUS' => 0.67,
        'perl'       => '5.6.1',
    },
    build_requires => {
        'Test::More' => 0,
    },    
    script_files        => [ 
                  'bin/phylip2nex.pl',
                           ],
    add_to_cleanup      => [ 'Bio-NEXUS-Import-*' ],
);

$builder->create_build_script();
