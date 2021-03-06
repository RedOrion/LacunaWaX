
package LacunaWaX::MainSplitterWindow::LeftPane::BodiesTreeCtrl {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Data::Dumper;
    use Moose;
    use MIME::Base64;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TREE_ITEM_ACTIVATED EVT_ENTER_WINDOW);
    use Wx::Perl::TreeView;
    use Wx::Perl::TreeView::SimpleModel;

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        required    => 1,
        documentation => q{
            The left pane of the main splitter window.
        }
    );

    #########################################

    has 'bodies_item_id' => (
        is              => 'rw', 
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The 'Bodies' leaf, which looks like the root item, as it's the top level item visible.
        }
    );

    has 'colonies_item_id' => (
        is              => 'rw', 
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The 'Colonies' leaf.
        }
    );
    has 'stations_item_id' => (
        is              => 'rw', 
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The 'Stations' leaf.
        }
    );
    has 'embassy_item_id' => (
        is              => 'rw', 
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The 'Embassy' leaf.
        }
    );

    has 'dispatch' => (
        is          => 'rw',
        isa         => 'HashRef',
        lazy_build  => 1,
        documentation => q{
            dispatch table for leaf click actions
        }
    );

    has 'root_item_id' => (
        is              => 'rw',
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The true root item.  Not visisble because of the wxTR_HIDE_ROOT style.
        }
    );

    has 'treectrl' => (
        is          => 'rw',
        isa         => 'Wx::TreeCtrl',
        lazy_build  => 1,
    );

    has 'treemodel' => (
        is          => 'rw',
        isa         => 'Wx::Perl::TreeView::SimpleModel',
        lazy_build  => 1,
    );

    has 'treeview' => (
        is          => 'rw',
        isa         => 'Wx::Perl::TreeView',
        lazy_build  => 1,
    );


    sub BUILD {
        my $self = shift;
        $self->fill_tree;

        $self->_set_events();
        return $self;
    };
    sub _build_szr_main {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Main Sizer');
    }#}}}
    sub _build_dispatch {#{{{
        my $self    = shift;

        my $dispatch = {
            colonies => sub{ $self->toggle_expansion_state( 'colonies' ) },
            stations => sub{ $self->toggle_expansion_state( 'stations' ) },
            embassy  => sub{ $self->toggle_expansion_state( 'embassy' ) },
            default => sub {
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::DefaultPane'
                );
            },
            rearrange => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane', $planet
                );
            },
            name => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SummaryPane', $planet
                );
            },
            glyphs => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::GlyphsPane',
                    $planet,
                    { required_buildings  => {'Archaeology Ministry' => undef}, }
                );
            },
            repair => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::RepairPane',
                    $planet,
                );
            },
            spies => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SpiesPane',
                    $planet,
                    { required_buildings => {'Intelligence Ministry' => undef} } 
                );
            },
            bfg => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::BFGPane',
                    $planet,
                    { required_buildings => {'Parliament' => 25} } 
                );
            },
            incoming => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SSIncoming',
                    $planet,
                    { required_buildings => {'Police' => undef} } 
                );
            },
            orbiting => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SSOrbiting',
                    $planet,
                    { required_buildings => {'Police' => undef} } 
                );
            },

            ### This is the per-station propsitions pane
            propositions => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::PropositionsPane',
                    $planet,
                    { 
                        required_buildings  => {'Parliament' => undef}, 
                        nothrob             => 1,
                    } 
                );
            },
            ### This is the embassy's propsitions pane
            emb_props => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::EmbassyPropositionsPane',
                    $planet,
                );
            },
            sshealth => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SSHealth',
                    $planet,
                );
            },
        };
        return $dispatch;
    }#}}}
    sub _build_treectrl {#{{{
        my $self = shift;
        my $v = Wx::TreeCtrl->new(
            $self->parent, -1, wxDefaultPosition, wxDefaultSize, 
            wxTR_DEFAULT_STYLE
            |wxTR_HAS_BUTTONS
            |wxTR_LINES_AT_ROOT
            |wxSUNKEN_BORDER
            |wxTR_HIDE_ROOT
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_treemodel {#{{{
        my $self = shift;

        my $b64_colonies = encode_base64(join q{:}, ('colonies'));
        my $b64_stations = encode_base64(join q{:}, ('stations'));
        my $b64_embassy  = encode_base64(join q{:}, ('embassy'));


        my $tree_data = {
            node    => 'Root',
            childs  => [
                { 
                    node => 'Colonies',
                    data => $b64_colonies,
                },
                { 
                    node => 'Stations',
                    data => $b64_stations,
                },
            ],
        };

        my $c = wxTheApp->game_client;
        if( $c->primary_embassy_id and $c->primary_embassy_id >= 1 ) {
            push @{$tree_data->{'childs'}}, { node => 'Embassy', data => $b64_embassy };
        }

        my $v = Wx::Perl::TreeView::SimpleModel->new( $tree_data );
        return $v;
    }#}}}
    sub _build_treeview {#{{{
        my $self = shift;
        my $model;
        my $v = Wx::Perl::TreeView->new(
            $self->treectrl, $self->treemodel
        );

        return $v;
    }#}}}
    sub _build_root_item_id {#{{{
        my $self = shift;
        return $self->treeview->treectrl->GetRootItem;
    }#}}}
    sub _build_bodies_item_id {#{{{
        my $self = shift;
        my($body_id, $cookie) = $self->treeview->treectrl->GetFirstChild($self->root_item_id);
        return $body_id;
    }#}}}
    sub _build_colonies_item_id {#{{{
        my $self = shift;
        ### This only works if Colonies is listed first.
        my($body_id, $cookie) = $self->treeview->treectrl->GetFirstChild($self->root_item_id);
        return $body_id;
    }#}}}
    sub _build_stations_item_id {#{{{
        my $self = shift;
        ### This only works if Colonies is listed first, and Stations listed 
        ### second.
        my( $colonies_id, $stations_id, $cookie );
        ($colonies_id, $cookie) = $self->treeview->treectrl->GetFirstChild($self->root_item_id);

        ### Two different ways of finding the stations_id -- both work, proven 
        ### by the die().
        ($stations_id, $cookie) = $self->treeview->treectrl->GetNextChild($self->root_item_id, $cookie);
        #$stations_id = $self->treeview->treectrl->GetNextSibling($colonies_id);
        #die $self->treectrl->GetItemText( $stations_id );

        return $stations_id;
    }#}}}
    sub _build_embassy_item_id {#{{{
        my $self = shift;
        ### This only works if Colonies is listed first, Stations second, and 
        ### Embassy third.
        my( $colonies_id, $stations_id, $embassy_id, $cookie );
        ($colonies_id, $cookie) = $self->treeview->treectrl->GetFirstChild($self->root_item_id);

        ($stations_id, $cookie) = $self->treeview->treectrl->GetNextChild($self->root_item_id, $cookie);
        ($embassy_id, $cookie) = $self->treeview->treectrl->GetNextChild($self->root_item_id, $cookie);

        return $embassy_id;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TREE_ITEM_ACTIVATED(    $self->treeview->treectrl, $self->treeview->treectrl->GetId,    sub{$self->OnTreeClick(@_)}     );
        EVT_ENTER_WINDOW(           $self->treeview->treectrl,                                      sub{$self->OnMouseEnter(@_)}    );
        return 1;
    }#}}}

    sub bold_toplevel_leaves {#{{{
        my $self = shift;

        $self->treectrl->SetItemFont( $self->colonies_item_id, wxTheApp->get_font('bold_para_text_1') );
        $self->treectrl->SetItemFont( $self->stations_item_id, wxTheApp->get_font('bold_para_text_1') );
        $self->treectrl->SetItemFont( $self->embassy_item_id, wxTheApp->get_font('bold_para_text_1') );
    }#}}}
    sub bold_planet_names_orig {#{{{
        my $self = shift;

        my( $planet_id, $cookie ) = $self->treeview->treectrl->GetFirstChild( $self->bodies_item_id );
        my $cnt = 1;
        $self->treectrl->SetItemFont( $planet_id, wxTheApp->get_font('bold_para_text_1') );

        while( $planet_id = $self->treeview->treectrl->GetNextSibling($planet_id) ) {
            last unless $planet_id->IsOk;
            $cnt++;
            $self->treectrl->SetItemFont( $planet_id, wxTheApp->get_font('bold_para_text_1') );
        }
        return $cnt;
    }#}}}
    sub fill_tree {#{{{
        my $self = shift;

        return unless( wxTheApp->game_client and wxTheApp->game_client->ping );

        my $colonies = [];
        foreach my $cname( sort{lc $a cmp lc $b} keys %{wxTheApp->game_client->colonies} ) {#{{{

            my $pid = wxTheApp->game_client->planet_id($cname);
            my $colony_node = {
                node    => $cname,
                data    => encode_base64(join q{:}, ('name', $pid)),
                childs  => [],
            };

            ### Both Planet and Station
            my $b64_rearrange   = encode_base64(join q{:}, ('rearrange', $pid));
            ### Planet
            my $b64_glyphs      = encode_base64(join q{:}, ('glyphs', $pid));
            my $b64_repair      = encode_base64(join q{:}, ('repair', $pid));
            my $b64_spies       = encode_base64(join q{:}, ('spies', $pid));

            push @{ $colony_node->{'childs'} }, { node => 'Glyphs',     data => $b64_glyphs };
            push @{ $colony_node->{'childs'} }, { node => 'Rearrange',  data => $b64_rearrange };
            push @{ $colony_node->{'childs'} }, { node => 'Repair',     data => $b64_repair };
            push @{ $colony_node->{'childs'} }, { node => 'Spies',      data => $b64_spies };

            push @{$colonies}, $colony_node;
        }#}}}

        my $stations = [];
        foreach my $sname( sort{lc $a cmp lc $b} keys %{wxTheApp->game_client->stations} ) {#{{{

            my $pid = wxTheApp->game_client->planet_id($sname);
            my $station_node = {
                node    => $sname,
                data    => encode_base64(join q{:}, ('name', $pid)),
                childs  => [],
            };

            ### Both Planet and Station
            my $b64_rearrange   = encode_base64(join q{:}, ('rearrange', $pid));
            ### Station
            my $b64_bfg         = encode_base64(join q{:}, ('bfg', $pid));
            my $b64_inc         = encode_base64(join q{:}, ('incoming', $pid));
            my $b64_orbit       = encode_base64(join q{:}, ('orbiting', $pid));
            my $b64_props       = encode_base64(join q{:}, ('propositions', $pid));
            my $b64_sshealth    = encode_base64(join q{:}, ('sshealth', $pid));

            ### Space Station
            push @{ $station_node->{'childs'} }, { node => 'Fire the BFG',   data => $b64_bfg };
            push @{ $station_node->{'childs'} }, { node => 'Health Alerts',  data => $b64_sshealth };
            push @{ $station_node->{'childs'} }, { node => 'Incoming',       data => $b64_inc };
            push @{ $station_node->{'childs'} }, { node => 'Orbiting',       data => $b64_orbit };
            push @{ $station_node->{'childs'} }, { node => 'Propositions',   data => $b64_props };
            push @{ $station_node->{'childs'} }, { node => 'Rearrange',      data => $b64_rearrange };

            push @{$stations}, $station_node;
        }#}}}

        my $embassy = [#{{{
            {
                node    => 'Propositions',
                data    => encode_base64('emb_props'),
                childs  => [],
            },
        ];#}}}


        unless($^O eq 'MSWin32') {
            ### Add some empty nodes at the bottom of the last branch, or the 
            ### last item will be obscured by the bottom of the frame.
            ###
            ### On Windows, those two empty nodes show up; there are branch 
            ### outlines to them (and they're empty so the outlines go 
            ### nowhere).  And even with everything expanded, nothing runs off 
            ### the bottom, so skip it there.
            ###
            ### These empty nodes only help if the Embassy branch is open, and 
            ### the user then opens the Stations branch as well, and there are 
            ### enough stations to run the Embassy off the bottom.
            ###
            ### If the Embassy branch is not open, the empty nodes we're 
            ### adding to the bottom of it won't show, and the Embassy leaf 
            ### itself will run off the bottom.
            ###
            ### This is bogus; I need to figure out how to add margin to the 
            ### whole control instead of these shims.
            for(1..2) {
                my $empty_node = {
                    node    => q{},
                    childs  => [],
                };
                push @{$embassy}, $empty_node;
            }
        }

        my $model_data = $self->treeview->model->data;
        $model_data->{'childs'}[0]{'childs'} = $colonies;
        $model_data->{'childs'}[1]{'childs'} = $stations;
        $model_data->{'childs'}[2]{'childs'} = $embassy;

        $self->treeview->model->data( $model_data );
        $self->treeview->reload();

        ### Start out with only the colonies expanded.
        $self->toggle_expansion_state( 'colonies' );
        $self->bold_toplevel_leaves();

        return 1;
    }#}}}
    sub toggle_expansion_state {#{{{
        my $self = shift;
        my $leaf = shift;

        my $id = ($leaf eq 'colonies') 
            ? $self->colonies_item_id 
            : ($leaf eq 'stations')
                ? $self->stations_item_id
                : $self->embassy_item_id;
 
        if( $self->treectrl->IsExpanded($id) )  { $self->treectrl->Collapse( $id )  }
        else                                    { $self->treectrl->Expand( $id ) }

        return 1;
    }#}}}

    sub OnTreeClick {#{{{
        my $self        = shift;
        my $tree_ctrl   = shift;
        my $tree_event  = shift;

        my $leaf = $tree_event->GetItem();
        my $root = $tree_ctrl->GetRootItem();

        if( $leaf == $tree_ctrl->GetRootItem ) {
            wxTheApp->poperr("Selected item is root item.");
            return;
        }

        my $text = $tree_ctrl->GetItemText($leaf);
        if( my $data = $tree_ctrl->GetItemData($leaf) ) {#{{{


            my $hr = $data->GetData;
=pod

 $hr = {
  'cookie' => {
    'data' => base64-encoded cookie data that we don't care about
    'node' => 'Glyphs'
  },
  'data' => base64-encoded leaf data that we _do_ care about
 };

=cut


            my ($action, $pid, @args)   = split /:/, decode_base64($hr->{'data'} || q{});
            my $planet                  = wxTheApp->game_client->planet_name($pid);

            $action ||= q{}; 
            if( defined $self->dispatch->{$action} ) {
                &{ $self->dispatch->{$action} }($planet);
            }
        }#}}}
        else {
            say "got no data.";
        }


        return 1;
    }#}}}
    sub OnMouseEnter {#{{{
        my $self    = shift;
        my $control = shift;    # Wx::TreeCtrl
        my $event   = shift;    # Wx::MouseEvent

        ### Set focus on the treectrl when the mouse enters to allow 
        ### scrollwheel events to affect the tree rather than whatever they'd 
        ### been affecting previously.
        unless( wxTheApp->main_frame->splitter->left_pane->has_focus ) {
            $control->SetFocus;
            wxTheApp->main_frame->splitter->focus_left();
        }

        $event->Skip();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

