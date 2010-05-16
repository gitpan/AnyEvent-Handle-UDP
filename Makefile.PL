use inc::Module::Install;

name q(AnyEvent-Handle-UDP);
all_from q(lib/AnyEvent/Handle/UDP.pm);

requires q(AnyEvent) => 5.26;
requires q(Errno) => 1.00;
requires q(Carp) => 1.00;
requires q(IO::Socket::INET) => 1.20;

test_requires q(Test::More) => 0.90;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-Handle-UDP);
homepage q(http://search.cpan.org/dist/AnyEvent-Handle-UDP);
repository q(git://github.com/jhthorsen/anyevent-handle-udp.git);

auto_install;
WriteAll;
