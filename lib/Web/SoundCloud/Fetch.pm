use MooseX::Declare;
use true;

class Web::SoundCloud::Fetch {
    use MooseX::Types::URI qw(Uri);
    use MooseX::Types::JSON qw(JSON);
    use HTML::TreeBuilder;
    use WWW::Mechanize;
    use WWW::Mechanize::TreeBuilder;
    use JSON::XS;
    use Moose::Autobox;
    use MP3::Info;

    BEGIN { 
        use Moose::Util::TypeConstraints;
        use MooseX::Types::Moose qw(Int ArrayRef HashRef);
        use MooseX::Types -declare => [qw( MechanizeXPTB )];

        type MechanizeXPTB, where { 
            blessed $_[0]
            # and   $_[0]->can("does")
            # and   $_[0]->does("WWW::Mechanize::TreeBuilder");
        };
        
        coerce MechanizeXPTB, 
            from HashRef, via {
                my $mech = WWW::Mechanize->new(%{$_[0]});
                WWW::Mechanize::TreeBuilder->meta->apply($mech,
                    tree_class => 'HTML::TreeBuilder::XPath'
                );
                $mech;
            },
            from ArrayRef, via {
                my $mech = WWW::Mechanize->new(@{$_[0]});
                WWW::Mechanize::TreeBuilder->meta->apply($mech,
                    tree_class => 'HTML::TreeBuilder::XPath'
                );
                $mech;
            },
        ;

    }


    has 'uri' => ( isa => Uri, is => 'ro', required => 1, coerce => 1, );
    has 'mech' => (
        isa     => MechanizeXPTB,
        is      => 'ro',
        coerce  => 1,
        default => sub { { cookie_jar => {}, } },
    );

    has json_sections => (
        isa => ArrayRef[HashRef], is => 'ro', lazy_build => 1,
    );

    method _build_json_sections {
        $self->mech->success or $self->mech->get( $self->uri );
        my @json = map {
            my $elem = "" . ($_->content_list)[0];
            $elem =~ s#window.SC.bufferTracks.push\((.*)\);#$1#; 
            decode_json($elem);
        } $self->mech->look_down( 
            _tag => 'script',
            sub { 
                my $content = ($_[0]->content_list)[0];
                return unless defined $content;
                return $content =~ m{window.SC.bufferTracks.push}; 
            },
        );
        \@json;
    }

    method filename (Int $section_number) {
        my $section = $self->json_sections->[$section_number];
        join( " - ", $section->at("user")->at("username"), $section->at("title") ) . ".mp3";
    }

    method fetch (Int $section_number) {
        my $section = $self->json_sections->[$section_number];
        my $filename = $self->filename($section_number);
        $self->mech->get($section->at("streamUrl"));
        if ($self->mech->success) {
            $self->mech->save_content( $filename );
            warn "saved content to $filename";

            my $mp3 = MP3::Info->new($filename);
            $mp3->set_mp3tag($section->at("title"), $section->at("user")->at("username"));
            warn "set MP3 ID3v1 tag for $filename";
        } else {
            warn "Couldn't save MP3 stream: ", $self->mech->status;
        }
        $self->mech->back;
    }
}
