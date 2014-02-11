use v5.14;
use warnings;
use DateTime::TimeZone;
use FindBin;
use Try::Tiny;

use lib $FindBin::Bin . '/../lib';

### This must exist here for perlApp to understand it needs Moose in time.
use Moose;

use LacunaWaX::Model::Container;
use LacunaWaX::Schedule;
use LacunaWaX::Util;

my $root_dir    = LacunaWaX::Util::find_root();
my $db_file     = join '/', ($root_dir, 'user', 'lacuna_app.sqlite');
my $db_log_file = join '/', ($root_dir, 'user', 'lacuna_log.sqlite');

my $dt = try {
    DateTime::TimeZone->new( name => 'local' )->name();
};
$dt ||= 'UTC';

my $bb = LacunaWaX::Model::Container->new(
    name            => 'ScheduleContainer',
    root_dir        => $root_dir,
    db_file         => $db_file,
    db_log_file     => $db_log_file,
    log_time_zone   => $dt,
);

my $scheduler = LacunaWaX::Schedule->new( 
    bb          => $bb,
    schedule    => 'autovote',
);
$scheduler->autovote();

exit 0;

