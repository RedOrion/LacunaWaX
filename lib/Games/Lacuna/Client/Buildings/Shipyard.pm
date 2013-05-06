package Games::Lacuna::Client::Buildings::Shipyard;
{
  $Games::Lacuna::Client::Buildings::Shipyard::VERSION = '0.003';
}
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Buildings;

our @ISA = qw(Games::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view_build_queue      => { default_args => [qw(session_id building_id)] },
    subsidize_build_queue => { default_args => [qw(session_id building_id)] },
    get_buildable         => { default_args => [qw(session_id building_id)] },
    build_ship            => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

Games::Lacuna::Client::Buildings::Shipyard - The Shipyard building

=head1 SYNOPSIS

  use Games::Lacuna::Client;

=head1 DESCRIPTION

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
