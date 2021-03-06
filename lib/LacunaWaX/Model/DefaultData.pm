
package LacunaWaX::Model::DefaultData {
    use v5.14;
    use Carp;
    use Moose;
    use Try::Tiny;

    has 'servers' => (
        is          => 'rw',
        isa         => 'HashRef',
        lazy_build  => 1,
    );
    has 'stations' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        lazy_build  => 1,
    );

    sub _build_servers {#{{{
        my $self = shift;
        return {
            ### Servers display in the app ordered by ID ASC.  The 'order' key 
            ### here controls the order in which they're added to the table so 
            ### they end up displaying in the desired order.  A little hacky 
            ### but works.
            US1 => {
                url      => 'us1.lacunaexpanse.com',
                order    => 1,
                protocol => 'http',
            },
            PT => {
                url      => 'pt.lacunaexpanse.com',
                order    => 2,
                protocol => 'http',
            }
        };
    }#}}}
    sub _build_stations {#{{{
        my $self = shift;

        ### this is now much less important.  If a new station shows up in the 
        ### tree incorrectly showing Planet child leaves, the user can now 
        ### just double-click on the station's name and that left tree will be 
        ### automatically updated to correctly show the Station child leaves 
        ### (without restarting the app.)

        return [
            '71423',    # Graegheum 3
            '11971',    # Urn Oochaid Rie 2
            '596628',   # SASS Absolut Punishment
            '578020',   # SASS Afrass
            '288617',   # SASS Ashanti High Lightning
            '471875',   # SASS Basestar
            '468709',   # SASS bmots 01
            '110204',   # SASS bmots 02
            '359715',   # SASS Dexter's Lab
            '215640',   # SASS Free Clinic
            '754487',   # SASS Heart of Darkness
            '285952',   # SASS Iasph Pienu 8
            '463023',   # SASS One-Eye
            '491837',   # SASS Origins
            '645488',   # SASS Parilla
            '71377',    # SASS PAW1
            '82971',    # SASS PAW2
            '80082',    # SASS PAW3
            '98819',    # SASS PAW4
            '59842',    # SASS PAW5
            '72782',    # SASS PAW6
            '144584',   # SASS Quatch
            '299393',   # SASS Silmarilos Outpost 01
            '86085',    # SASS Silmarilos Outpost 02
            '289142',   # SASS Silmarilos Silvertongue
            '370033',   # SASS Silmarilos Trelinator
            '360612',   # SASS temp
            '144971',   # SASS Ultra
            '593205',   # SASS Unimatrix 0
            '61303',    # SASS Wine Cellar
            '451704',   # SASS-3
            '401175',   # SASS-=Ceu Prulino=-
            '370819',   # SASS-Nice 'n' Sleazy
            '373714',   # SASS-Sin City
            '372199',   # SASS-Sleazy 2
            '434194',   # SASS-Sweet Mary
            '291773',   # SASS-Wandering Star
            '355132',   # SASS4
            '360983',   # SASS5
        ];
    }#}}}

    sub add_servers {#{{{
        my $self    = shift;
        my $schema  = shift;

        unless( ref $schema eq 'LacunaWaX::Model::Schema' ) {
            croak "Incorrect schema passed to add_servers."
        }

        my $hr = $self->servers;
        foreach my $srvr_name( sort{$hr->{$a}{'order'} <=> $hr->{$b}{'order'}} keys %{$self->servers} ) {
            my $row = $schema->resultset('Servers')->find_or_create(
                {
                    name     => $srvr_name,
                    url      => $hr->{$srvr_name}{'url'},
                    protocol => $hr->{$srvr_name}{'protocol'},
                },
                { key => 'unique_by_name' }
            );
        }
        return 1;
    }#}}}
    sub add_stations {#{{{
        my $self    = shift;
        my $schema  = shift;

        unless( ref $schema eq 'LacunaWaX::Model::Schema' ) {
            croak "Incorrect schema passed to add_servers."
        }

        foreach my $sid(@{ $self->stations }) {
            my $row = $schema->resultset('BodyTypes')->find_or_create(
                {
                    body_id      => $sid,
                    server_id    => 1,
                },
                { key => 'one_per_server' }
            );
            $row->type_general('space station');
            $row->update;
        }
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

LacunaWaX::Model::DefaultData - Default data to be added to databases post-deploy

=head1 SYNOPSIS

 $data   = LacunaWaX::Model::DefaultData->new();
 $schema = LacunaWaX::Model::Schema->new(...);

 $servers     = $data->servers;
 $station_ids = $data->stations;

 $data->add_servers($schema);
 $data->add_stations($schema);  # Adds US1 known stations

=head1 DESCRIPTION

This module provides all known game servers, but all other data refers to the 
main play server, US1. 

=cut

