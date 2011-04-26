package Foo;
use Something;
use Somerole;
use Moose;
use Moose::Util::TypeConstraints;

BEGIN {
    subtype 'Something123', as 'Object', where { $_[0]->isa("SomethingElse") };
    subtype 'Blah', as 'Something123', where { 
        $_[0]->can("does") and $_[0]->does("Somerole");
    };

    coerce 'Something123', from 'HashRef', via { Something->new(%{$_[0]}) };

    coerce 'Blah', 
        from 'Something123', via { Somerole->meta->apply($_[0]) },
        from 'HashRef', via { 
            my $x = find_type_constraint("Something123")->coerce($_[0]);
            Somerole->meta->apply($x);
            $x;
        }
    ;
}

has blah => ( isa => 'Blah', is => 'ro', coerce => 1, );

1;
