use strict;
use warnings;
use lib q(lib);
use AnyEvent::Handle::UDP;
use Test::More;

plan tests => 5;

my $udp;

eval { $udp = AnyEvent::Handle::UDP->new(tls => 'foo') };
like($@, qr{is invalid}, 'cannot construct AE::H::UDP with tls');

eval { $udp = AnyEvent::Handle::UDP->new(connect => 'foo') };
like($@, qr{not implemented}, 'connect => "foo" is not implemented');

eval { $udp = AnyEvent::Handle::UDP->new() };
like($@, qr{is required}, 'missing arguments to new');

eval { $udp = AnyEvent::Handle::UDP->new(listen => '!"#¤%&/()=') };
like($@, qr{IO::Socket::INET}, 'listen => foo is invalid');

eval { $udp = AnyEvent::Handle::UDP->new(listen => 'localhost:61234') };
ok($udp, 'AE::H::UDP constructed');
