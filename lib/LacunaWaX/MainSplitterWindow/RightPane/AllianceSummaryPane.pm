
package LacunaWaX::MainSplitterWindow::RightPane::AllianceSummaryPane {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Data::Dumper;
    use DateTime;
    use LacunaWaX::Model::Dates;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    has 'ancestor' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane',
        required    => 1,
    );

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    #########################################

    has 'text'          => (is => 'rw', isa => 'Str',       lazy_build => 1   );

    has 'profile'       => (is => 'rw', isa => 'HashRef',   lazy_build => 1   );
    has 'create_date'   => (is => 'rw', isa => 'DateTime',  lazy_build => 1   );
    has 'description'   => (is => 'rw', isa => 'Str',       lazy_build => 1   );
    has 'id'            => (is => 'rw', isa => 'Int',       lazy_build => 1   );
    has 'influence'     => (is => 'rw', isa => 'Num',       lazy_build => 1   );
    has 'leader'        => (is => 'rw', isa => 'Str',       lazy_build => 1   );
    has 'members'       => (is => 'rw', isa => 'ArrayRef',  lazy_build => 1   );
    has 'name'          => (is => 'rw', isa => 'Str',       lazy_build => 1   );
    has 'stations'      => (is => 'rw', isa => 'ArrayRef',  lazy_build => 1   );

    has 'szr_header'    => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1   );
    has 'lbl_header'    => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1   );
    has 'lbl_text'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1   );

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->lbl_text, 0, 0, 0);

        $self->_set_events();
        return $self;
    }
    sub _build_szr_res_grid {#{{{
        my $self = shift;

        ### 7 rows (5 data, 1 header, 1 spacer), 4 cols, 2px vgap, 50px hgap.
        my $szr_res_grid = Wx::FlexGridSizer->new(7, 4, 2, 50);

        return $szr_res_grid;
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header');
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $self->name,
            wxDefaultPosition, 
            Wx::Size->new(-1, 30)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        return $v;
    }#}}}
    sub _build_lbl_text {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $self->text, 
            wxDefaultPosition, 
            ### If you start changing the height on this, check the result on 
            ### both a station and on a planet.  Station text is bigger.  
            ### Also, stations with warning text ("OMG we haven't seize our 
            ### own star!") will need even more height here.
            Wx::Size->new(400,-1)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_create_date {#{{{
        my $self = shift;

        my $dt = LacunaWaX::Model::Dates->parse_lacuna( $self->profile->{'date_created'} );
        return $dt;
    }#}}}
    sub _build_description {#{{{
        my $self = shift;
        return $self->profile->{'description'};
    }#}}}
    sub _build_id {#{{{
        my $self = shift;
        return $self->profile->{'id'};
    }#}}}
    sub _build_influence {#{{{
        my $self = shift;
        return $self->profile->{'influence'};
    }#}}}
    sub _build_leader {#{{{
        my $self = shift;

        my $leader = q{};
        foreach my $m( @{$self->profile->{'members'}} ) {
            if( $m->{'id'} eq $self->profile->{'leader_id'} ) {
                $leader = $m->{'name'};
                last;
            }
        }
        return $leader;
    }#}}}
    sub _build_members {#{{{
        my $self = shift;
        my @members = map{ $_->{'name'} }@{ $self->profile->{'members'} };
        return [@members];
    }#}}}
    sub _build_name {#{{{
        my $self = shift;

        return $self->profile->{'name'};
    }#}}}
    sub _build_profile {#{{{
        my $self = shift;
        my $p = wxTheApp->game_client->get_alliance_profile;
        return $p->{'profile'};
    }#}}}
    sub _build_stations {#{{{
        my $self = shift;
        my @stations = map{ $_->{'name'} }@{ $self->profile->{'space_stations'} };
        return [@stations];
    }#}}}
    sub _build_text {#{{{
        my $self  = shift;
        
        my $text = $self->description . "\n\n";

        $text .= "Led by " . $self->leader . ".\n";
        $text .= "Created on " . $self->create_date_full .  " UTC.\n";
        $text .= "Holding " . (scalar @{$self->stations}) . " space stations, with " . $self->influence . " influence.\n\n";

        $text .= "Current Members:\n";
        foreach my $m( sort {lc $a cmp lc $b}@{$self->members} ) {
            $text .= "\t$m\n";
        }

        return $text;
    }#}}}
    sub _set_events {}

    sub create_date_full {#{{{
        my $self = shift;
        return $self->create_date->ymd . q{ at } . $self->create_date->hms;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
