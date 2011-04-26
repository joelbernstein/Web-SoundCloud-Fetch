use MooseX::Declare;

class Web::SoundCloud::Fetch {
    use MooseX::Types::URI qw(Uri);
    use MooseX::Types::JSON qw(JSON);
    use HTML::TreeBuilder;
    use WWW::Mechanize;
    use WWW::Mechanize::TreeBuilder;

    BEGIN { 
        use MooseX::Types::Moose qw(ArrayRef HashRef);
        use MooseX::Types -declare => [qw( Mechanize MechanizeXPTB )];
        subtype Mechanize, as class_type('WWW::Mechanize');
        coerce Mechanize, 
            from ArrayRef, via { WWW::Mechanize->new(@{ $_[0] }); },
            from HashRef,  via { WWW::Mechanize->new(%{ $_[0] }); }
        ;

        subtype MechanizeXPTB, as Mechanize, where { 
            blessed $_[0]
              and   $_[0]->can("does")
              and   $_[0]->does("WWW::Mechanize::TreeBuilder");
        };
        
        coerce MechanizeXPTB, 
            from Mechanize, via {
                WWW::Mechanize::TreeBuilder->meta->apply($_[0],
                    tree_class => 'HTML::TreeBuilder::XPath'
                );
                $_[0];
            },
            from ArrayRef|HashRef, via {
                my $mech = Mechanize->coerce($_[0]);
                WWW::Mechanize::TreeBuilder->meta->apply($mech,
                    tree_class => 'HTML::TreeBuilder::XPath'
                );
                $mech;
            }
        ;
                


    }


    has 'uri' => ( isa => Uri, is => 'ro', required => 1, );
    has 'mech' => (
        isa     => MechanizeXPTB,
        is      => 'ro',
        coerce  => 1,
        default => sub { {} },
    );

    method extract_json_sections {
        $self->mech->success or $self->mech->get( $self->uri );
        my @json = map {
            my $elem = $_->as_text;
            $elem =~ s#window.SC.bufferTracks.push\((.*)\);#$1#; 
            decode_json($elem);
        } $self->mech->look_down( 
            _tag => 'script',
            sub { $_[0]->as_text =~ m{window.SC.bufferTracks.push}; },
        );
       use DDS; Dump(\@json);
    }
}


1;
