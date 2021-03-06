
### SITTERVOTE

package LacunaWaX::MainSplitterWindow::RightPane::EmbassyPropositionsPane::PropRow {
    use v5.14;
    use Carp;
    use Data::Dumper;   # just for debug
    use DateTime;
    use DateTime::Duration;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_TEXT_ENTER EVT_CLOSE);

    has 'ancestor' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane::EmbassyPropositionsPane',
        required    => 1,
    );

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    #########################################

    has 'main_sizer'    => (is => 'rw', isa => 'Wx::BoxSizer',  lazy_build => 1, documentation => 'vertical');
    has 'embassy'       => (is => 'rw', isa => 'Maybe[Games::Lacuna::Client::Buildings::Embassy]', lazy_build => 1 );
    has 'ally_members'  => (is => 'rw', isa => 'Maybe[HashRef]', lazy_build => 1);

    has 'prop' => (is => 'rw', isa => 'Maybe[HashRef]', 
        documentation => q{
            This must be passed in from the outside if you want to display 
            anything but a blank row or a header.
        }
    );


    has 'stop_voting' => (is => 'rw', isa => 'Int', lazy => 1, default => 0,
        documentation => q{
            If the user closes the status window, this will be set to True, in which 
            case sitter voting should cease.
        }
    );

    has 'my_vote' => (is => 'rw', isa => 'Str', lazy_build => 1,
        documentation => q{
            'Yes', 'No', or 'None'.
            Only applies to props for which you've already voted.
        }
    );

    has 'is_header' => (
        is              => 'rw',
        isa             => 'Int',
        lazy            => 1,
        default         => 0,
        documentation   => q{
            If true, the produced Row will be a simple header with no input
            controls and no events.  The advantage is that the header's size will 
            match the size of the rest of the rows you're about to produce.
        }
    );

    has 'is_footer' => (
        is              => 'rw',
        isa             => 'Int',
        default         => 0,
        documentation   => q{
            If true, the produced Row contain a "Vote for all props" button
            Like the header, the footer's size will match the size of the rest 
            of the rows you're about to produce.
            Mutually exclusive with 'is_header'.  If both are sent, is_header 
            wins.
        }
    );
    has 'rows' => (
        is      => 'rw',
        isa     => 'ArrayRef',
        lazy    => 1, 
        default => sub{ [] },
        documentation => q{
            This must get passed to the footer row, and only to the footer 
            row.
            It's the PropositionPane's ->rows, which contains all of the 
            propositions displayed on the screen.  We need to have this to be 
            able to vote for all of the props (which is the reason for the 
            existence of the footer).
        }
    );

    has 'row_height'  => (is => 'rw', isa => 'Int', lazy => 1, default => 25);

    has 'cast_me_sizer'         => (is => 'rw', isa => 'Wx::Sizer',     lazy_build => 1, documentation => 'horizontal');
    has 'cast_sitters_sizer'    => (is => 'rw', isa => 'Wx::Sizer',     lazy_build => 1, documentation => 'horizontal');

    has 'name_width'            => (is => 'rw', isa => 'Int', lazy => 1, default => 110);
    has 'proposed_on_width'     => (is => 'rw', isa => 'Int', lazy => 1, default => 80);
    has 'votes_needed_width'    => (is => 'rw', isa => 'Int', lazy => 1, default => 60);
    has 'votes_yes_width'       => (is => 'rw', isa => 'Int', lazy => 1, default => 40);
    has 'votes_no_width'        => (is => 'rw', isa => 'Int', lazy => 1, default => 40);
    has 'my_vote_width'         => (is => 'rw', isa => 'Int', lazy => 1, default => 60);
    has 'button_width'          => (is => 'rw', isa => 'Int', lazy => 1, default => 35);

    has 'name_header'               => (is => 'rw', isa => 'Wx::StaticText');
    has 'proposed_on_header'        => (is => 'rw', isa => 'Wx::StaticText');
    has 'votes_needed_header'       => (is => 'rw', isa => 'Wx::StaticText');
    has 'votes_yes_header'          => (is => 'rw', isa => 'Wx::StaticText');
    has 'votes_no_header'           => (is => 'rw', isa => 'Wx::StaticText');
    has 'my_vote_header'            => (is => 'rw', isa => 'Wx::StaticText');
    has 'cast_my_vote_header'       => (is => 'rw', isa => 'Wx::StaticText');
    has 'cast_sitters_vote_header'  => (is => 'rw', isa => 'Wx::StaticText');

    has 'lbl_name'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_proposed_on'   => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_votes_needed'  => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_votes_yes'     => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_votes_no'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_my_vote'       => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);

    has 'btn_me_yes'        => (is => 'rw', isa => 'Wx::Button',    lazy_build => 1);
    has 'btn_me_no'         => (is => 'rw', isa => 'Wx::Button',    lazy_build => 1);
    has 'btn_sitters_yes'   => (is => 'rw', isa => 'Wx::Button',    lazy_build => 1);
    has 'btn_all_yes'       => (is => 'rw', isa => 'Wx::Button',    lazy_build => 1);

    has 'dialog_status'     => (is => 'rw', isa => 'LacunaWaX::Dialog::Status', lazy_build => 1             );
    has 'waiting_for_enter' => (is => 'rw', isa => 'Int',                       lazy => 1,      default => 0);

    sub BUILD {
        my $self    = shift;
        my $params  = shift;


        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers
        return $self->_make_header if $self->is_header;
        return $self->_make_footer if $self->is_footer;

        $self->main_sizer->Add($self->lbl_name, 0, 0, 0);
        $self->main_sizer->Add($self->lbl_proposed_on, 0, 0, 0);
        $self->main_sizer->Add($self->lbl_votes_needed, 0, 0, 0);
        $self->main_sizer->Add($self->lbl_votes_yes, 0, 0, 0);
        $self->main_sizer->Add($self->lbl_votes_no, 0, 0, 0);
        $self->main_sizer->Add($self->lbl_my_vote, 0, 0, 0);

        $self->main_sizer->Add($self->cast_me_sizer, 0, 0, 0);
        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->cast_sitters_sizer, 0, 0, 0);

        wxTheApp->Yield;
        $self->_set_events();

        return $self;
    }
    sub _build_ally_members {#{{{
        my $self = shift;
        my $ally_hash = {};

        $ally_hash = try {
            wxTheApp->game_client->get_alliance_members();
        }
        catch {
            wxTheApp->poperr("Could not find your alliance members.  You're most likely out of RPCs; wait a minute and try again.", "Error!");
            $self->btn_sitters_yes->Enable(1);
            $self->clear_dialog_status;
            return $ally_hash;
        };
        return $ally_hash;
    }#}}}
    sub _build_cast_me_sizer {#{{{
        my $self = shift;

        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Cast Me');
        $v->Add($self->btn_me_yes, 0, 0, 0);
        $v->Add($self->btn_me_no, 0, 0, 0);

        return $v;
    }#}}}
    sub _build_cast_sitters_sizer {#{{{
        my $self = shift;

        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Cast Sitters');
        $v->Add($self->btn_sitters_yes, 0, 0, 0);

        return $v;
    }#}}}
    sub _build_dialog_status {#{{{
        my $self = shift;

        my $v = LacunaWaX::Dialog::Status->new( 
            parent  => $self,
            title   => 'Sitter Voting Status',
            recsep  => '-=-=-=-=-=-=-',
        );
        $v->hide;
        return $v;
    }#}}}
    sub _build_embassy {#{{{
        my $self = shift;
        my $c = wxTheApp->game_client;
        my $emb = $c->building( id => $c->primary_embassy_id, type => 'embassy' );
        return $emb;
    }#}}}
    sub _build_lbl_name {#{{{
        my $self = shift;

        my($text, $desc) = ($self->prop) 
            ? ($self->prop->{'name'}, $self->prop->{'description'}) 
            : (q{}, q{});
        if(length $text > 17) { # Summarize long proposition names
            substr $text, 14, (length $text), '...';
        }

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text, 
            wxDefaultPosition, 
            Wx::Size->new($self->name_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        my $tt = Wx::ToolTip->new( $desc );
        $v->SetToolTip($tt);

        return $v;
    }#}}}
    sub _build_lbl_proposed_on {#{{{
        my $self = shift;


        my $player_name = $self->prop->{'proposed_by'}{'name'} // q{};
        my $abbrv_station = my $full_station = ($self->prop) ? $self->prop->{'station'} : q{};
        $abbrv_station =~ s/^(\w)ASS\s+/$1-/;
        if(length $abbrv_station > 13) { # Summarize long station names
            substr $abbrv_station, 10, (length $abbrv_station), '...';
        }

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $abbrv_station, 
            wxDefaultPosition, 
            Wx::Size->new($self->proposed_on_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        my $tt = Wx::ToolTip->new( "Proposed on $full_station by $player_name" );
        $v->SetToolTip($tt);

        return $v;
    }#}}}
    sub _build_lbl_votes_needed {#{{{
        my $self = shift;

        my $text = ($self->prop) ? $self->prop->{'votes_needed'} : q{};
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text, 
            wxDefaultPosition, 
            Wx::Size->new($self->votes_needed_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_lbl_votes_yes {#{{{
        my $self = shift;

        my $text = ($self->prop) ? $self->prop->{'votes_yes'} : q{};
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text, 
            wxDefaultPosition, 
            Wx::Size->new($self->votes_yes_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_lbl_votes_no {#{{{
        my $self = shift;

        my $text = ($self->prop) ? $self->prop->{'votes_no'} : q{};
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text, 
            wxDefaultPosition, 
            Wx::Size->new($self->votes_no_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_lbl_my_vote {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $self->my_vote, 
            wxDefaultPosition, 
            Wx::Size->new($self->my_vote_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_main_sizer {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Main');
    }#}}}
    sub _build_btn_me_yes {#{{{
        my $self = shift;

        my $v = Wx::Button->new($self->parent, -1, 
            "Yes",
            wxDefaultPosition, 
            Wx::Size->new($self->button_width, $self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        my $enabled = ($self->my_vote eq 'None') ? 1 : 0;
        $v->Enable($enabled);

        return $v;
    }#}}}
    sub _build_btn_me_no {#{{{
        my $self = shift;

        my $v = Wx::Button->new($self->parent, -1, 
            "No",
            wxDefaultPosition, 
            Wx::Size->new($self->button_width,$self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        my $enabled = ($self->my_vote eq 'None') ? 1 : 0;
        $v->Enable($enabled);

        return $v;
    }#}}}
    sub _build_btn_sitters_yes {#{{{
        my $self = shift;

        ### button_width * 2 because there's no sitters_no button.
        my $v = Wx::Button->new($self->parent, -1, 
            "Yes",
            wxDefaultPosition, 
            ### + 20 to make the sitters button stand out a bit
            Wx::Size->new($self->button_width + 20, $self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_btn_all_yes {#{{{
        my $self = shift;

        ### button_width * 2 because there's no sitters_no button.
        my $v = Wx::Button->new($self->parent, -1, 
            "Yes to all props",
            wxDefaultPosition, 
            ### + 20 to make the sitters button stand out a bit
            Wx::Size->new(100, $self->row_height)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_btn_sitters_no {#{{{
        my $self = shift;

        ### This method exists just to explain its absence (this space 
        ### intentionally left blank).
        ### 
        ### Casting a 'no' vote for all of your sitters seems dangerous and 
        ### probably not what anybody ever wants.

        return 1;
    }#}}}
    sub _build_my_vote {#{{{
        my $self = shift;
        my $text = (defined $self->prop->{'my_vote'}) 
            ?  ($self->prop->{'my_vote'}) ? 'Yes' : 'No'
            : 'None';
        return $text;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;

        ### The header has no controls so setting events on it is pointless.
        ### Furthermore, setting these events will call lazy builders on some of 
        ### those non-existent controls which will explode.
        ###
        ### We should never get here on the header and footer rows; they're 
        ### returning before _set_events gets called.  Still, safety is nice 
        ### and this isn't hurting anything.
        return 1 if $self->is_header or $self->is_footer;

        EVT_BUTTON( $self->parent, $self->btn_me_yes->GetId,        sub{$self->OnMyVote(@_, 1)}         );
        EVT_BUTTON( $self->parent, $self->btn_me_no->GetId,         sub{$self->OnMyVote(@_, 0)}         );
        EVT_BUTTON( $self->parent, $self->btn_sitters_yes->GetId,   sub{$self->OnSittersVote(@_, 1)}    );
        return 1;
    }#}}}

    sub _make_header {#{{{
        my $self = shift;

        ### On the off chance the user sent both is_header and is_footer, 
        ### unset is_footer.
        $self->is_footer(0);

        $self->name_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Name: ',
                wxDefaultPosition, Wx::Size->new($self->name_width,$self->row_height)
            )
        );
        $self->proposed_on_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Station: ',
                wxDefaultPosition, Wx::Size->new($self->proposed_on_width,$self->row_height)
            )
        );
        $self->votes_needed_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Need: ',
                wxDefaultPosition, Wx::Size->new($self->votes_needed_width,$self->row_height)
            )
        );
        $self->votes_yes_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Yes: ',
                wxDefaultPosition, Wx::Size->new($self->votes_yes_width,$self->row_height)
            )
        );
        $self->votes_no_header(
            Wx::StaticText->new(
                $self->parent, -1, 'No: ',
                wxDefaultPosition, Wx::Size->new($self->votes_no_width,$self->row_height)
            )
        );
        $self->my_vote_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Mine: ',
                wxDefaultPosition, Wx::Size->new($self->my_vote_width,$self->row_height)
            )
        );
        $self->cast_my_vote_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Me: ',
                ### 2 buttons + 2 pixels between those (estimate) + 5 pixel 
                ### spacer between "me" and "sitter" button groups
                wxDefaultPosition, Wx::Size->new(($self->button_width * 2 + 2 + 5), $self->row_height)
            )
        );
        $self->cast_sitters_vote_header(
            Wx::StaticText->new(
                $self->parent, -1, 'Sitters: ',
                ### No "+ 5" because there's no spacer after this button 
                ### group.
                wxDefaultPosition, Wx::Size->new(($self->button_width * 2 + 2), $self->row_height)
            )
        );

        $self->name_header->SetFont                 ( wxTheApp->get_font('header_7') );
        $self->proposed_on_header->SetFont          ( wxTheApp->get_font('header_7') );
        $self->votes_needed_header->SetFont         ( wxTheApp->get_font('header_7') );
        $self->votes_yes_header->SetFont            ( wxTheApp->get_font('header_7') );
        $self->votes_no_header->SetFont             ( wxTheApp->get_font('header_7') ); 
        $self->my_vote_header->SetFont              ( wxTheApp->get_font('header_7') ); 
        $self->cast_my_vote_header->SetFont         ( wxTheApp->get_font('header_7') ); 
        $self->cast_sitters_vote_header->SetFont    ( wxTheApp->get_font('header_7') ); 

        $self->main_sizer->Add($self->name_header, 0, 0, 0);
        $self->main_sizer->Add($self->proposed_on_header, 0, 0, 0);
        $self->main_sizer->Add($self->votes_needed_header, 0, 0, 0);
        $self->main_sizer->Add($self->votes_yes_header, 0, 0, 0);
        $self->main_sizer->Add($self->votes_no_header, 0, 0, 0);
        $self->main_sizer->Add($self->my_vote_header, 0, 0, 0);
        $self->main_sizer->Add($self->cast_my_vote_header, 0, 0, 0);
        $self->main_sizer->Add($self->cast_sitters_vote_header, 0, 0, 0);
        return;
    }#}}}
    sub _make_footer {#{{{
        my $self = shift;

        EVT_BUTTON( $self->parent, $self->btn_all_yes->GetId,   sub{$self->OnAllVote(@_, 1)}        );
        $self->main_sizer->AddSpacer(420);
        $self->main_sizer->Add($self->btn_all_yes, 0, 0, 0);
        return;
    }#}}}
    sub attempt_vote {#{{{
        my $self                = shift;
        my $sitter_rec          = shift;
        my $prop                = shift;
        my $prop_has_passed     = 0;

        wxTheApp->Yield;
        if($self->stop_voting) { $self->stop_voting(0); $self->btn_sitters_yes->Enable(1); return; }

        my $player = $sitter_rec->player_name;
        return if defined $self->ancestor->over_rpc->{$player};
        return if defined $self->ancestor->already_voted->{$player};
        $self->dialog_status_say("Working on $player.");

        ### Need a new client per sitter, logged in as that sitter, NOT as the 
        ### player currently using LacunaWaX.
        my $sitter_client = try {
            wxTheApp->game_client->relog($sitter_rec->player_name, $sitter_rec->sitter);
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            $self->dialog_status_say("*** I was unable to login for $player - they may be totally out of RPCs. ***");
            $self->ancestor->over_rpc->{$player}++;
            return;
        } or do{ $self->dialog_status_say_recsep(); return; };
        if($self->stop_voting) { $self->stop_voting(0); $self->btn_sitters_yes->Enable(1); $self->dialog_status_say_recsep(); return; }

        ### We need to call this to set the sitter client's primary_embassy_id
        my $sitter_status = $sitter_client->get_empire_status();

        ### Get embassy using sitter's client
        $self->dialog_status_say("Getting embassy using ${player}'s client...");
        my $sitter_emb = try {
            #$sitter_client->building( id => $self->embassy->{'building_id'}, type => 'embassy' );
            $sitter_client->building( id => $sitter_client->primary_embassy_id, type => 'embassy' );
        }
        catch {
            $self->dialog_status_say("*** I was unable to find the primary embassy for $player because:\n\t$_\n");
            return;
        } or do{ $self->dialog_status_say_recsep(); return; };
        if($self->stop_voting) { $self->stop_voting(0); $self->btn_sitters_yes->Enable(1); $self->dialog_status_say_recsep(); return; }

        ### Vote using the sitter's embassy
        $self->dialog_status_say("Attempting to cast 'yes' vote...");
        my $rv = try {
            ### The call to cast_vote periodically stalls out.  The alarm 
            ### rescues us from that stall.
            local $SIG{ALRM} = sub { croak "voting stall"; };
            alarm 5;


            ### SITTERVOTE
            ### That 'tag' comment exists so this chunk of code is easy to 
            ### find, please do not delete it. 
            ###
            ### to force 'no' votes , swap the comments below
            my $rv = $sitter_emb->cast_vote($prop->{'id'}, 1);     # Yes (regular)
#           my $rv = $sitter_emb->cast_vote($prop->{'id'}, 0);     # No
            alarm 0;

            return $rv;
        }
        catch {
            alarm 0;
            my $msg = (ref $_) ? $_->text : $_;

            if( $msg =~ m/you have already voted/i ) {
                $self->dialog_status_say("$player has already voted on this prop.");
                $self->ancestor->already_voted->{$player} = $sitter_rec;
            }
            elsif( $msg =~ m/this proposition has already passed/i ) {
                return { passed => 1 };
            }
            elsif( $msg =~ m/(slow down|internal error)/i ) {
                $self->dialog_status_say("*** $player just hit the 60 RPC limit! ***");
            }
            elsif( $msg =~ m/stall/i ) {
                $self->dialog_status_say("Voting stalled.");
            }
            elsif( $msg =~ m/has already made the maximum number of requests/i ) {
                $self->dialog_status_say("*** $player has used all 10,000 RPCs for the day! ***");
                $self->ancestor->over_rpc->{$player}++;
            }
            else {
                $self->dialog_status_say("*** Attempt to vote for $player failed for an unexpected reason:\n\t$msg ***");
            }

            return;
        };
        unless($rv) {
            ### $player is over the RPC limit or has already voted or something.
            $self->dialog_status_say("Skipping $player");
            $self->dialog_status_say_recsep();
            return;
        }
        if($self->stop_voting) { $self->stop_voting(0); $self->btn_sitters_yes->Enable(1); $self->dialog_status_say_recsep(); return; }

        my $voted_ok = 0;
        if( ref $rv eq 'HASH') {
            if( $rv->{proposition}{my_vote} ) {
                $voted_ok++;
            }
            if( $rv->{passed} ) {
                $voted_ok++;
                $prop_has_passed = 1;
            }
        }
        $self->dialog_status_say("Finished with " . $sitter_rec->player_name . q{.});
        $self->dialog_status_say_recsep();

        return($voted_ok, $prop_has_passed);
    }#}}}
    sub sitter_vote_on_prop {#{{{
        my $self = shift;
        my $row  = shift;

=pod

Given a PropRow object, votes on that row's proposition using all recorded 
sitters.

=cut

        my $schema = wxTheApp->main_schema;
        my @recorded_sitter_recs    = $schema->resultset('SitterPasswords')->search(
                                        { server_id => wxTheApp->server->id, },
                                        { order_by  => { -asc => 'RANDOM()' } }
                                        );
        unless(@recorded_sitter_recs) {
            wxTheApp->poperr("You don't have any sitters recorded yet, so you can't cast votes on their behalf.  See the Sitter Manager tool.", "Error");
            $self->btn_sitters_yes->Enable(1);
            $self->clear_dialog_status;
            return;
        }
 
        my $current_yes         = $row->lbl_votes_yes->GetLabelText;
        my $total_needed        = $row->lbl_votes_needed->GetLabelText;
        my $voting_members      = [];
        my $prop_has_passed     = 0;
        SITTER:
        foreach my $sitter_rec(@recorded_sitter_recs) {
            ### User might have recorded a sitter of a player not in the current 
            ### alliance.
            next SITTER unless defined $self->ally_members->{ $sitter_rec->player_id };

            my $voted_ok;
            ($voted_ok, $prop_has_passed) = $self->attempt_vote($sitter_rec, $row->prop);
            if( $voted_ok ) {
                push @{$voting_members}, $sitter_rec->player_name;
                $current_yes++;
                $row->lbl_votes_yes->SetLabel($current_yes);
                $prop_has_passed++ if $current_yes >= $total_needed;
            }
            last SITTER if $prop_has_passed;
        }

        unless( $prop_has_passed ) {
            ### We skipped attempting to vote for members who'd already been 
            ### recorded as having voted on a different prop.  They /probably/ 
            ### voted on this prop, but only /probably/.  Since this prop hasn't 
            ### passed yet, we'll fall back to trying those members now.
            my @try_these = values %{ $self->ancestor->already_voted };
            $self->ancestor->clear_already_voted();

            ALREADY_VOTED:
            foreach my $sitter_rec(@try_these) {
                next ALREADY_VOTED unless defined $self->ally_members->{ $sitter_rec->player_id };
                my $voted_ok;
                ($voted_ok, $prop_has_passed) = $self->attempt_vote($sitter_rec, $row->prop);
                if( $voted_ok ) {
                    push @{$voting_members}, $sitter_rec->player_name;
                    $current_yes++;
                    $row->lbl_votes_yes->SetLabel($current_yes);
                    $prop_has_passed++ if $current_yes >= $total_needed;
                }
                last ALREADY_VOTED if $prop_has_passed;
            }
        }

        if(@{$voting_members}) {
            my $votes_cast = @{$voting_members};
            $self->dialog_status_say("\nVotes have been cast on this prop for the following $votes_cast players:\n");
            $self->dialog_status_say( (join q{, }, @{$voting_members}) . qq{\n} );

            if( $prop_has_passed ) {
                $self->dialog_status_say(
                    "This prop has passed.  It may have passed without having to use all of"
                    . " your saved sitter passwords, so the list of names above may be missing"
                    . " some who never actually voted."
                )
            }
        }
        else {
            $self->dialog_status_say("\nNo votes have been cast on this prop.");
        }

        $self->dialog_status_say_recsep();
        $self->dialog_status_say_recsep();
        $self->dialog_status_say('');
        $self->dialog_status_say('');

    }#}}}
    before 'clear_dialog_status' => sub {#{{{
        my $self = shift;
 
        ### Call the dialog_status object's own close method, which removes its 
        ### wxwidgets, before clearing this object's dialog_status attribute.
        if($self->has_dialog_status) {
            $self->dialog_status->close;
        }
        return 1;
    };#}}}

    ### Wrappers around dialog_status's methods to first check for existence of 
    ### dialog_status.
    sub dialog_status_say {#{{{
        my $self = shift;
        my $msg  = shift;
        if( $self->has_dialog_status ) {
            try{ $self->dialog_status->say($msg) };
        }
        return 1;
    }#}}}
    sub dialog_status_say_recsep {#{{{
        my $self = shift;
        if( $self->has_dialog_status ) {
            try{ $self->dialog_status->say_recsep };
        }
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;

        if($self->has_dialog_status) {
            $self->clear_dialog_status;
        }
        return 1;
    }#}}}
    sub OnDialogEnter {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::CommandEvent
        $self->waiting_for_enter(0);
        return 1;
    }#}}}
    sub OnAllVote {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::CommandEvent
        my $vote    = shift;    # 1 or 0

        unless($self->embassy) {
            wxTheApp->poperr("We seem not to have a primary embassy; no voting is possible.", "Error");
            return;
        }

        my $conf_msg = q{You're about to vote 'Yes' for all props on this page for all of your sitters.  Are you sure?};
        unless( wxYES == wxTheApp->popconf($conf_msg) ) {
            wxTheApp->popmsg("OK; bailing.");
            return;
        }

        $self->dialog_status->show();
        wxTheApp->Yield;
        foreach my $row( @{$self->rows} ) {
            $self->dialog_status_say("Voting on prop '" . $row->prop->{'name'} . "'");
            $self->dialog_status_say_recsep();
            $row->btn_sitters_yes->Enable(0);  # Disable the button to keep the user from double-clicking.
            $self->sitter_vote_on_prop($row);
        }
        if( $self->ancestor->chk_close_status->IsChecked ) {
            $self->clear_dialog_status; # also closes it
        }

        wxTheApp->endthrob;
        $self->dialog_status_say("All props have been voted on.  You may close this window.");
        return 1;
    }#}}}
    sub OnMyVote {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::CommandEvent
        my $vote    = shift;    # 1 or 0

        unless($self->embassy) {
            wxTheApp->poperr("We seem not to have a primary embassy; no voting is possible.", "Error");
            return;
        }

        wxTheApp->throb;
        my $rv = try {
            $self->embassy->cast_vote($self->prop->{'id'}, $vote);
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            wxTheApp->poperr("Attempt to vote failed with: $msg", "Error!");
            wxTheApp->endthrob;
            return;
        } or return;
        wxTheApp->endthrob;


        my $vote_text;
        if( $vote ) {
            my $current_yes = $self->lbl_votes_yes->GetLabelText;
            $self->lbl_votes_yes->SetLabel(++$current_yes);
            $vote_text = 'Yes';
 
        }
        else {
            my $current_no = $self->lbl_votes_no->GetLabelText;
            $self->lbl_votes_no->SetLabel(++$current_no);
            $vote_text = 'No';
        }

        ### Disable my voting buttons for this prop; only one vote is allowed, 
        ### so further clicks on either button will just result in failure.
        $self->btn_me_yes->Enable(0);
        $self->btn_me_no->Enable(0);
        wxTheApp->popmsg("Your vote of '$vote_text' has been recorded.", "Success!");
        return 1;
    }#}}}
    sub OnSittersVote {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::CommandEvent
        my $vote    = shift;    # 1 or 0

        unless($self->embassy) {
            wxTheApp->poperr("We seem not to have a primary embassy; no voting is possible.", "Error");
            return;
        }
        unless($vote) {
            wxTheApp->popmsg("I'm thinking that allowing anybody to vote 'no' for all of their sitters is a bad idea.", "Vote not recorded");
            return;
        }

        $self->btn_sitters_yes->Enable(0);  # Disable the button to keep the user from double-clicking.

        ### When there are lots of props to process, the throbber periodically 
        ### starts.  I have not been able yet to figure out why, but the damn 
        ### thing will suddenly show a bar partway through the gauge, and that 
        ### bar will very infrequently throb.
        ### For now, just reset it at the beginning of voting for each prop. 
        ### This won't stop it from periodically showing up, but will clean it 
        ### up when it does.
        wxTheApp->endthrob;

        ### We _do_ want to directly call dialog_status->show here.  It's 
        ### possible the user:
        ###     - Started a sitter vote loop
        ###     - Cancelled it by closing the status window for whatever reason
        ###     - Re-thought that and re-clicked the sitter voting button.
        ### At this point, we would have completely cleared dialog_status when 
        ### the user closed its window, so it no longer exists.
        ### This direct call will, in that case, recreate it.
        $self->dialog_status->show();
        wxTheApp->Yield;

        $self->sitter_vote_on_prop($self);

        if( $self->ancestor->chk_close_status->IsChecked ) {
            $self->clear_dialog_status; # also closes it
        }

        ### See comment at the other endthrob call top this method.
        wxTheApp->endthrob;
        return 1;
    }#}}}
    sub OnDialogStatusClose {#{{{
        my $self    = shift;
        my $status  = shift;    # LacunaWaX::Dialog::Status

        ### This is not a true event.  It gets called explicitly by 
        ### Dialog::Status's OnClose event.
        ###
        ### I'd prefer to set some sort of an event, but am not sure exactly how 
        ### to do that.  So for now, the sitter voting loop just has many "if 
        ### $self->stop_voting ..." conditions to emulate an event.

        $self->stop_voting(1);
        if( $self->has_dialog_status ) {
            $self->clear_dialog_status;
        }
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head2 STATUS DIALOGS

Each PropRow has its own dialog_status attribute with a lazy builder method.  If 
the user closes that dialog with a mouseclick:
    - Dialog::Status::OnClose gets called, completely destroying the wxwidgets 
      dialog.
    - That OnClose event then calls this class's OnDialogStatusClose() 
      pseudo-event method, which clears the dialog_status from the PropRow 
      object.
    - This could happen at any time, without warning.
 
So any calls to dialog_status in here (eg dialog_status->say(...);) need to be 
wrapped in checks that first ensure the thing still exists; dialog_status_say() 
and dialog_status_say_recsep() methods exist to that end.


When removing that dialog_status ourselves (progammatically, rather than when 
the user closes it with a mouseclick), we need to destroy the actual wxwidgets 
items as well as remove the Moose dialog_status attribute from the PropRow 
object.

Simply calling $self->clear_dialog_status _will_ take care of that, due to the 
'before' method modifier.


If you're testing something, search for "SITTERVOTE" in this file.  There's 
commented-out code there that you can turn on that will pretend to vote but not 
really vote (so you don't have to keep voting and then going back to the game 
to create a new prop to test on).

Also, if you need to force a 'No' vote for some specific reason, there's code 
at that same SITTERVOTE tag to do that.

=cut

