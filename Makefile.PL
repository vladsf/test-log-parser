use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
    'Mojolicious' => '9.22',
    'DBI' => '1.643',
    'DBD::Pg' => '3.15.1'
  },
  test => {TESTS => 't/*.t'}
);
