package Somerole;
use Moose::Role;

has 'bar' => ( isa => 'Str', is => 'ro', default => sub { "jelly" } );

1;
