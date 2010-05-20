package AnyEvent::Handle::UDP;

=head1 NAME

AnyEvent::Handle::UDP - AnyEvent::Handle for client/server UDP sockets

=head1 VERSION

0.02

=head1 DESCRIPTION

I suddenly decided to leave any L<AnyEvent> code (including
L<AnyEvent::TFTPd>), due to a community and development model that
is indeed very hard to work with. If you want this module, please
drop me mail and I'll hand over the maintenance.

=head1 SYNOPSIS

  use AnyEvent::Handle::UDP;

  my $udp = AnyEvent::Handle::UDP->new(
                listen => 'localhost:12345',
                read_size => 512,
                on_read => sub {
                    my $handle = shift;
                    print "packet=", $handle->rbuf, "\n";
                    $handle->{'rbuf'} = '';
                },
            );

=cut

use strict;
# use warnings; ?!
use Carp qw/confess/;
use IO::Socket::INET;
use Errno qw(EAGAIN EINTR);
use AnyEvent::Util qw(WSAEWOULDBLOCK);
use base 'AnyEvent::Handle';

our $VERSION = '0.02';

=head1 ATTRIBUTES

=head2 socket

Holds an L<IO::Socket::INET> object, representing the connection.

=head2 peername

Proxy method for L<IO::Socket::INET::peername>.

=head2 peerhost

Proxy method for L<IO::Socket::INET::peerhost>.

=head2 peerport

Proxy method for L<IO::Socket::INET::peerport>.

=head2 sockname

Proxy method for L<IO::Socket::INET::sockname>.

=head2 sockhost

Proxy method for L<IO::Socket::INET::sockhost>.

=head2 sockport

Proxy method for L<IO::Socket::INET::sockport>.

=cut

sub socket { $_[0]->{'fh'} }
sub peername { $_[0]->{'fh'}->peername }
sub peerhost { $_[0]->{'fh'}->peerhost }
sub peerport { $_[0]->{'fh'}->peerport }
sub sockname { $_[0]->{'fh'}->sockname }
sub sockhost { $_[0]->{'fh'}->sockhost }
sub sockport { $_[0]->{'fh'}->sockport }

=head1 METHODS

=head2 new

The constructor supports the same arguments as
L<AnyEvent::Handle::new()>, except: tls*.

To create a listener:

 AnyEvent::Handle::UDP->new(
    listen => "$host:$port",
 );

Not yet implemented: C<connect>.

Does not make any sense for UDP: C<on_prepare>, C<on_connect>,
C<on_connect_error>, C<keepalive>, C<oobinline> and C<on_eof>.

=cut


sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    my @not_supported = qw/
        on_prepare on_connect on_connect_error on_eof oobinline keepalive
        tls tls_ctx on_starttls on_stoptls
    /;

    for my $k (@not_supported) {
        if($self->{$k}) {
            confess "Argument ($k) is invalid";
            return;
        }
    }

    $self->{'read_size'} ||= 8192;

    unless($self->{'fh'}) {
        if($self->{'listen'}) {
            $self->{'fh'} = IO::Socket::INET->new(
                                LocalAddr => $self->{'listen'},
                                Proto => 'udp',
                                Blocking => 0,
                            ) or confess $@;
        }
        elsif($self->{'connect'}) {
            confess 'Argument (connect) is not implemented';
            return;
        }
        else {
            confess 'Argument (listen|connect) is required';
            return;
        }
    }

    $self->_start;

    return $self;
}

=head2 start_read

See L<AnyEvent::Handle::start_read()>. This method is a modified version
which use C<recv()> on the socket instead of C<sysread()>.
The peer data is available inside C<on_read()>, but must be stored away,
since it will be overwritten on next C<recv()>.

=cut

sub start_read {
   my $self = shift;

   unless($self->{'_rw'} or $self->{'_eof'} or !$self->{'fh'}) {
        Scalar::Util::weaken($self);

        $self->{'_rw'} = AE::io $self->{'fh'}, 0, sub {
            my $rbuf = \$self->{'rbuf'};
            my $peer = $self->{'fh'}->recv($$rbuf, $self->{'read_size'}, length $$rbuf);
            my $len;

            unless(defined $peer) {
                return;
            }

            $len = length $$rbuf;

            if($len > 0) {
                $self->{'_activity'} = $self->{'_ractivity'} = AE::now;
                $self->_drain_rbuf;
            }
            elsif(defined $len) {
                delete $self->{'_rw'};
                $self->{'_eof'} = 1;
                $self->_drain_rbuf;
            }
            elsif($! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
                return $self->_error($!, 1);
            }
        };
    }
}

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen C<< jhthorsen at cpan.org >>

=cut

1;
