package Sometest;
use strictures;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use_ok 'Foo';
ok my $foo = Foo->new( blah => {} ), "build a Foo";

1;
