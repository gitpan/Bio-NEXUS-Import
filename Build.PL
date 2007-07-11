use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::NEXUS::Import',
    license             => 'perl',
    dist_author         => 'Markus Riester <mriester@gmx.de>',
    dist_version_from   => 'lib/Bio/NEXUS/Import.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Bio::NEXUS'    => 0.67,
    },
    add_to_cleanup      => [ 'Bio-NEXUS-Import-*' ],
);

$builder->create_build_script();
