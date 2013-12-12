
package LacunaWaX::Dialog::Captcha {
    use v5.14;
    use Data::Dumper; $Data::Dumper::Indent = 1;
    use File::Temp;
    use LWP::UserAgent;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_TEXT_ENTER);
    extends 'LacunaWaX::Dialog::NonScrolled';

    has 'sizer_debug'   => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

    has 'captcha' => (
        is          => 'rw',
        isa         => 'Games::Lacuna::Client::Captcha',
        lazy_build  => 1
    );
    has 'line_height' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 30,
    );
    has 'size' => (
        is          => 'rw',
        isa         => 'Wx::Size',
        default     => sub{ Wx::Size->new(310, 80 + $_[0]->line_height) },
    );
    has 'ua' => (
        is          => 'rw',
        isa         => 'LWP::UserAgent',
        lazy_build  => 1
    );

    has 'bmp_captcha'   => (is => 'rw', isa => 'Wx::StaticBitmap'                                                       );
    has 'btn_reload'    => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1                                     );
    has 'btn_solution'  => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1                                     );
    has 'szr_image'     => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'vertical'        );
    has 'szr_solution'  => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'horizontal'      );
    has 'txt_solution'  => (is => 'rw', isa => 'Wx::TextCtrl',      lazy_build => 1                                     );

    sub BUILD {
        my $self = shift;

        $self->SetTitle( 'Captcha' );
        $self->SetSize( $self->size );
        $self->Centre();

        $self->bmp_captcha( $self->get_image() );
        $self->szr_image->Add($self->bmp_captcha, 0, 0, 0);

        $self->szr_solution->Add($self->txt_solution, 0, 0, 0);
        $self->szr_solution->Add($self->btn_solution, 0, 0, 0);
        $self->szr_solution->Add($self->btn_reload, 0, 0, 0);

        $self->main_sizer->Add($self->szr_image, 0, 0, 0);
        $self->main_sizer->Add($self->szr_solution, 0, 0, 0);

        $self->init_screen();
        $self->txt_solution->SetFocus();
        $self->ShowModal();
        return $self;
    }

    sub _build_btn_solution {#{{{
        my $self = shift;
        my $v = Wx::Button->new(
            $self, -1, 
            "Solve",
            wxDefaultPosition, 
            Wx::Size->new(75, $self->line_height)
        );
        return $v;
    }#}}}
    sub _build_btn_reload {#{{{
        my $self = shift;
        my $v = Wx::Button->new(
            $self, -1, 
            "Reload",
            wxDefaultPosition, 
            Wx::Size->new(75, $self->line_height)
        );
        return $v;
    }#}}}
    sub _build_szr_image {#{{{
        my $self = shift;
        return $self->build_sizer($self, wxVERTICAL, 'Image', 0);
    }#}}}
    sub _build_szr_solution {#{{{
        my $self = shift;
        return $self->build_sizer($self, wxHORIZONTAL, 'Solution', 0);
    }#}}}
    sub _build_txt_solution {#{{{
        my $self = shift;
        return Wx::TextCtrl->new(
            $self, -1, 
            q{},
            wxDefaultPosition, Wx::Size->new(150,$self->line_height),
            wxTE_PROCESS_ENTER
        );
    }#}}}
    sub _build_captcha {#{{{
        my $self = shift;
        my $c = try {
            $self->game_client->captcha;
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            $self->poperr($msg);
            return;
        };
        return $c;
    }#}}}
    sub _build_ua {#{{{
        my $self = shift;
        return LWP::UserAgent->new();
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(     $self, $self->btn_reload->GetId,        sub{$self->OnReload(@_)});
        EVT_BUTTON(     $self, $self->btn_solution->GetId,      sub{$self->OnSolution(@_)});
        EVT_TEXT_ENTER( $self, $self->txt_solution->GetId,      sub{$self->OnSolution(@_)});
        EVT_CLOSE(      $self,                                  sub{$self->OnClose(@_)});
        return 1;
    }#}}}

    sub get_image {#{{{
        my $self = shift;

        my $puzzle = $self->captcha->fetch();
        my $resp = $self->ua->get($puzzle->{'url'});
        unless( $resp->is_success ) {
            $self->poperr("Unable to retrieve captcha image!");
            return;
        }

        my $img = $resp->content;
        open my $sfh, '<', \$img or die "Unable to open stream: $!";
        my $wximg = Wx::Image->new($sfh, wxBITMAP_TYPE_ANY);
        $wximg->Rescale(300, 80);
        my $bmp = Wx::Bitmap->new($wximg);

        my $sbmp = Wx::StaticBitmap->new(
            $self, -1,
            $bmp,
            wxDefaultPosition,
            Wx::Size->new(300, 80),
            wxFULL_REPAINT_ON_RESIZE
        );
        return $sbmp;
    }#}}}

    sub OnClose {#{{{
        my $self = shift;
        my $dialog = shift;
        my $event = shift;
        $self->EndModal(1);
        $self->Destroy;
        return 1;
    }#}}}
    sub OnReload {#{{{
        my $self = shift;

        my $old_bmp = $self->bmp_captcha;

        $self->clear_captcha;
        my $new_bmp = $self->get_image;
        $self->bmp_captcha( $new_bmp );

        $self->szr_image->Replace( $old_bmp, $new_bmp );
        $self->szr_image->Layout;

        return 1;
    }#}}}
    sub OnSolution {#{{{
        my $self = shift;
        my $dialog = shift;
        my $event = shift;

        my $resp = $self->txt_solution->GetValue;
        my $rv = try {
            $self->captcha->solve($resp);
            return 1;
        }
        catch {
            $self->poperr("Sorry, '$resp' was incorrect.", "Whoops");
            $self->txt_solution->SetValue(q{});
            $self->OnReload();
            return 0;
            ### CHECK
            ### this should force a reload of the image (?)
        };

        if($rv) {
            $self->popmsg("Success", "Correct!") if $rv;
            $self->Close;
        }
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;