
package LacunaWaX::MainFrame::IntroPanel {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON);

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame',
        required    => 1,
    );

    ##########################################

    has 'is_on' => (is => 'rw', isa => 'Int', lazy => 1, default => 1);

    has 'main_panel'        => (is => 'rw', isa => 'Wx::Panel',     lazy_build => 1);
    has 'main_sizer'        => (is => 'rw', isa => 'Wx::Sizer',     lazy_build => 1);

    has 'top_panel'                 => (is => 'rw', isa => 'Wx::Panel',  lazy_build => 1                                );
    has 'top_panel_sizer'           => (is => 'rw', isa => 'Wx::Sizer',  lazy_build => 1, documentation => 'horizontal' );
    has 'top_panel_center_sizer'    => (is => 'rw', isa => 'Wx::Sizer',  lazy_build => 1, documentation => 'horizontal' );
    has 'bottom_panel'              => (is => 'rw', isa => 'Wx::Panel',  lazy_build => 1                                );
    has 'bottom_panel_sizer'        => (is => 'rw', isa => 'Wx::Sizer',  lazy_build => 1, documentation => 'vertical'   );

    has 'logo' => (is => 'rw', isa => 'Wx::StaticBitmap', lazy_build => 1);

    has 'has_enabled_button' => (
        is      => 'rw', 
        isa     => 'Bool',
        default => 0,
    );

    has 'lbl_firsttime' => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1,
    );

    has 'buttons' => (
        is => 'rw', isa => 'HashRef[Wx::Button]', lazy_build => 1,
        documentation => q{ server_id => Wx::Button },
    );

    sub BUILD {
        my $self = shift;

        $self->main_panel->Show(0);
        $self->add_connect_buttons;

        ### Top
        ### To center the image in the top panel, we nest a sizer in a sizer 
        ### with StretchSpacers around both.
        ###     From Robin Dunn's post halfway through this thread:
        ###     http://wxpython-users.1045709.n5.nabble.com/wxSizer-ALIGN-CENTER-td2371894.html
        $self->top_panel_center_sizer->AddStretchSpacer;
        $self->top_panel_center_sizer->Add($self->logo);
        $self->top_panel_center_sizer->AddStretchSpacer;

        $self->top_panel_sizer->AddStretchSpacer;
        $self->top_panel_sizer->Add( $self->top_panel_center_sizer, 1, wxALIGN_CENTER, 0);
        $self->top_panel_sizer->AddStretchSpacer;
        $self->top_panel->SetSizer($self->top_panel_sizer);

        ### Bottom
        $self->bottom_panel_sizer->AddStretchSpacer(1);
        foreach my $srvr_id(keys %{$self->buttons}) {
            $self->bottom_panel_sizer->Add( $self->buttons->{$srvr_id}, 0, wxALIGN_CENTER_VERTICAL|wxALIGN_CENTER_HORIZONTAL, 0);
        }

        unless( $self->has_enabled_button ) {
            $self->bottom_panel_sizer->AddSpacer(20);
            $self->lbl_firsttime->Show(1);
            $self->bottom_panel_sizer->Add( $self->lbl_firsttime, 0, wxALIGN_CENTER_VERTICAL|wxALIGN_CENTER_HORIZONTAL, 0 );
        }

        $self->bottom_panel_sizer->AddStretchSpacer(2);
        $self->bottom_panel->SetSizer($self->bottom_panel_sizer);

        ### Main
        $self->main_sizer->Add($self->top_panel,    2, wxEXPAND, 1);
        $self->main_sizer->Add($self->bottom_panel, 4, wxEXPAND, 1);
        $self->main_panel->SetSizer( $self->main_sizer );

        $self->_set_events();
        $self->main_panel->Show(1);
        return $self;
    }
    sub _build_bottom_panel {#{{{
        my $self = shift;
        my $panel = Wx::Panel->new(
            $self->main_panel, -1, 
            wxDefaultPosition, 
            Wx::Size->new(1,1),
            0,
            'midPanel',
        );
        $panel->SetBackgroundColour(Wx::Colour->new(0,0,0));
        return $panel;
    }#}}}
    sub _build_bottom_panel_sizer {#{{{
        my $self = shift;
        return Wx::BoxSizer->new(wxVERTICAL);
    }#}}}
    sub _build_buttons {#{{{
        return {};
    }#}}}
    sub _build_lbl_firsttime {#{{{
        my $self = shift;
        my $text = "Before you can do anything, you have to go to Edit... Preferences and enter your login info, or import preferences from a previously-installed version of LacunaWaX.";
        my $v = Wx::StaticText->new(
            $self->bottom_panel, -1, 
            $text, 
            wxDefaultPosition, 
            Wx::Size->new(800,150),
            wxALIGN_CENTRE,
        );
        $v->Show(0);
        $v->SetForegroundColour(Wx::Colour->new(200,200,200));
        $v->SetFont( wxTheApp->get_font('header_3') );
        return $v;
    }#}}}
    sub _build_logo {#{{{
        my $self = shift;

        ### The logo is already the correct size and does not need to be 
        ### rescaled.
        my $img  = wxTheApp->get_image( 'app/logo-280x70.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->top_panel, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new(-1, 150),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_main_sizer {#{{{
        return Wx::BoxSizer->new(wxVERTICAL);
    }#}}}
    sub _build_main_panel {#{{{
        my $self = shift;
        return Wx::Panel->new(
            $self->parent->frame, -1, 
            wxDefaultPosition, wxDefaultSize,
            0,
            'mainPanel'
        );
    }#}}}
    sub _build_top_panel {#{{{
        my $self = shift;
        my $panel = ( 
            Wx::Panel->new(
                $self->main_panel, -1, 
                wxDefaultPosition, 
                Wx::Size->new(1,1),
                wxFULL_REPAINT_ON_RESIZE,
                'topPanel',
            )
        );
        $panel->SetBackgroundColour(Wx::Colour->new(200,0,0));
        return $panel;
    }#}}}
    sub _build_top_panel_center_sizer {#{{{
        my $self = shift;
        return Wx::BoxSizer->new(wxHORIZONTAL);
    }#}}}
    sub _build_top_panel_sizer {#{{{
        my $self = shift;
        return Wx::BoxSizer->new(wxHORIZONTAL);
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        foreach my $srvr_id(keys %{$self->buttons}) {
            my $btn = $self->buttons->{$srvr_id};
            EVT_BUTTON( $self->main_panel,  $btn->GetId,   sub{wxTheApp->main_frame->OnGameServerConnect($srvr_id, @_)} );
        }
        return 1;
    }#}}}

    sub add_connect_buttons {#{{{
        my $self    = shift;
        my $schema = wxTheApp->main_schema;

        ### One connect button per server
        for my $srvr_id( sort{$a<=>$b}wxTheApp->server_ids ) {
            my $srvr_rec = wxTheApp->server_record_by_id($srvr_id);
            my $b = Wx::Button->new(
                $self->bottom_panel, -1,
                "Connect to " . $srvr_rec->name,
                wxDefaultPosition,
                Wx::Size->new(200, 30),
                0,
            );
            $b->SetFont( wxTheApp->get_font('para_text_2') );

            if(
                my $prefs = $schema->resultset('ServerAccounts')->find({
                    server_id => $srvr_id,
                    default_for_server => 1
                })
            ) {
                ### Disable the connect buttons until the user has entered their 
                ### credentials in Preferences
                if( $prefs->username and $prefs->password ) {
                    $self->has_enabled_button(1);
                }
                else {
                    $b->Disable; 
                }
            }
            else {
                $b->Disable;
            }
            $self->buttons->{$srvr_id} = $b;
        }

        ### On Windows, the first button takes focus automatically, but not on 
        ### Ubuntu.  Focusing it allows us to just slap the spacebar to 
        ### connect to the first server listed (which should be US1).
        my $first_id = (sort{$a<=>$b}(keys %{$self->buttons}))[0];
        $self->buttons->{$first_id}->SetFocus;

        return 1;
    }#}}}
    sub hide {#{{{
        my $self = shift;
        $self->main_panel->Show(0);
        return 1;
    }#}}}
    sub remove {#{{{
        my $self = shift;
        $self->is_on(0);
        my $rv = $self->main_panel->Destroy();
        return 1;
    }#}}}
    sub show {#{{{
        my $self = shift;
        $self->main_panel->Show(1);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
