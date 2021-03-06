
package LacunaWaX::Dialog::Prefs {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE);

    extends 'LacunaWaX::Dialog::NonScrolled';

    use LacunaWaX::Dialog::Prefs::TabAutovote;
    use LacunaWaX::Dialog::Prefs::TabGeneral;
    use LacunaWaX::Dialog::Prefs::TabServer;

    has 'notebook_size' => (is => 'rw', isa => 'Wx::Size',      lazy_build => 1                 );
    has 'notebook'      => (is => 'rw', isa => 'Wx::Notebook',  lazy_build => 1                 );

    has 'tab_autovote' => (
        is              => 'rw', 
        isa             => 'Maybe[LacunaWax::Dialog::Prefs::TabAutovote]', 
        lazy_build      => 1,
        documentation   => q{Will be undef unless we're connected to a server.}
    );

    has 'tab_general' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::Prefs::TabGeneral', 
        lazy_build  => 1,
    );

    has 'tab_server' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::Prefs::TabServer', 
        lazy_build  => 1,
    );

    sub BUILD {
        my($self, @params) = @_;
 
        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers
        $self->SetTitle( $self->title );
        $self->SetSize( $self->size );
        $self->make_non_resizable;

        $self->notebook->AddPage($self->tab_server->pnl_main, "Server");
        $self->notebook->AddPage($self->tab_autovote->pnl_main, "AutoVote") if $self->tab_autovote;
        $self->notebook->AddPage($self->tab_general->pnl_main, "General");

        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->notebook, 1, wxEXPAND, 0);

        $self->_set_events();
        $self->init_screen();
        return $self;
    };
    sub _build_notebook {#{{{
        my $self = shift;
        my $v = Wx::Notebook->new($self->dialog, -1, wxDefaultPosition, $self->notebook_size, 0);
        return $v;
    }#}}}
    sub _build_notebook_size {#{{{
        my $self = shift;
        my $s = Wx::Size->new(
            $self->GetClientSize->width - 10,
            $self->GetClientSize->height - 10
        );
        return $s;
    }#}}}
    sub _build_tab_autovote {#{{{
        my $self = shift;

        if( wxTheApp->server ) {
            my $av = LacunaWax::Dialog::Prefs::TabAutovote->new( parent => $self );
            return $av;
        }
    }#}}}
    sub _build_tab_server {#{{{
        my $self = shift;

        my $tab = LacunaWax::Dialog::Prefs::TabServer->new( parent => $self );
        return $tab;
    }#}}}
    sub _build_tab_general {#{{{
        my $self = shift;

        my $tab = LacunaWax::Dialog::Prefs::TabGeneral->new( parent => $self );
        return $tab;
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        ### 700 px high allows for 18 saved sitters.  Past 18, the screen will 
        ### need to be scrolled down to get to the button.
        my $s = wxDefaultSize;
        $s->SetWidth(400);
        $s->SetHeight(300);
        return $s;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return 'Sitter Manager';
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE($self, sub{$self->OnClose(@_)});
        return 1;
    }#}}}

    sub OnSavePrefs {#{{{
        my($self, $dialog, $event) = @_;

        my $server_name     = $self->tab_server->server_list->[ $self->tab_server->chc_server->GetCurrentSelection ];
        my $username_str    = $self->tab_server->txtbox_user->GetLineText(0);
        my $password_str    = $self->tab_server->txtbox_pass->GetLineText(0);
        my $schema          = wxTheApp->main_schema;

        ### Sanity check input
        unless( $username_str and $password_str ) {
            wxTheApp->poperr(
                'You must enter both a username and password',
                'Incomplete Credentials'
            );
            return;
        }
        my $server_rec = $schema->resultset('Servers')->find({ name => $server_name });
        return unless($server_rec);

        ### keep only one account per server.
        my $existing_server_accounts_rs = $schema->resultset('ServerAccounts')->search({server_id => $server_rec->id});
        $existing_server_accounts_rs->delete;

        ### Update account info 
        my $proto = ($self->tab_server->rdo_https->GetValue) ? 'https' : 'http';
        #my $proto = 'https';
        my $server_account = $schema->resultset('ServerAccounts')->find_or_create(
            {
                username        => $username_str,
                server_id       => $server_rec->id,
            },
            { join => 'server' }
        );
        $server_account->password( $password_str );
        $server_account->default_for_server( 1 );
        $server_account->update;

        ### Update protocol for the server.
        $server_rec->protocol( $proto );
        $server_rec->update;

        ### Update autovote prefs
        if( $self->tab_autovote ) {
            my $who = lc $self->tab_autovote->rdo_autovote->GetStringSelection();
            my $rec = $schema->resultset('ScheduleAutovote')->find_or_create({
                server_id  => wxTheApp->server->id
            });
            $rec->proposed_by($who);
            $rec->update;
        }

        ### Enable/Disable connection widgets.
        ### Menu item, two Connect buttons (on the Intro page).
        my $menu_file  = wxTheApp->menu_bar->menu_file;
        my $srvr_menu_id = $menu_file->itm_connect->connections->{ $server_account->server_id }->GetId;
        if( $username_str and $password_str ) {
            if( wxTheApp->has_intro_panel ) {
                wxTheApp->intro_panel->buttons->{ $server_account->server->id }->Enable(1);
                wxTheApp->intro_panel->lbl_firsttime->SetLabel('Thanks!  Click the button to login.');
                wxTheApp->intro_panel->bottom_panel_sizer->Layout();
            }
            $menu_file->itm_connect->Enable($srvr_menu_id, 1);
        }
        else {
            if( wxTheApp->has_intro_panel ) {
                wxTheApp->intro_panel->buttons->{ $server_account->server->id }->Disable();
            }
            $menu_file->itm_connect->Enable($srvr_menu_id, 0);
        }

        Wx::MessageBox("Your preferences have been saved.", 'Success!',  wxOK );
        $self->Destroy;
        return 1;
    }#}}}
    sub OnClose {#{{{
        my($self, $dialog, $event) = @_;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
