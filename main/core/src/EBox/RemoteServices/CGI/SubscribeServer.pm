# Copyright (C) 2008-2013 Zentyal S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
use strict;
use warnings;

package EBox::RemoteServices::CGI::SubscribeServer;
use base qw(EBox::CGI::ClientRawBase);

use EBox::Config;
use EBox::Global;
use EBox::Gettext;
use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use Cwd qw(realpath);
use HTTP::Date;
use Plack::Util;
use Sys::Hostname;
use TryCatch::Lite;


sub new
{
    my ($class, @params) = @_;
    my $self = $class->SUPER::new(@params);

    bless($self, $class);
    return $self;
}

sub _process
{
    my ($self) = @_;
    $self->{json} = {success => 0 };

    foreach my $param (qw(username password name)) {
        if (not $self->param($param)) {
            $self->{json}->{msg} = __x('Missing parameter: {par}', par => $param);
            return;
        }
    }

    my $username = $self->param('username');
    my $password = $self->param('password');
    my $name     = $self->param('name');

    my $remoteServices = EBox::Global->getInstance()->modInstance('remoteservices');
    $remoteServices->setUsername($username);
    $remoteServices->setPassword($password);    

    my $auth = $remoteServices->auth;
    if ((not exists $auth->{username}) or ($auth->{username} ne $username)) {
        $self->{json}->{msg} = __('Invalid credentials');
        $remoteServices->clearCredentials();
        return;
    }


    my $subscriptions = $remoteServices->listSubscriptions();
    if (not $subscriptions) {
        return;
    }
    my @rows = map {
        my $subs = $_;
        my $row = '<div>';
        $row .= $subs->{product_label} ;
        $row .= '</div>' . '<br/>';

    } @{$subscriptions};


    $self->{json}->{success} = 1;
    $self->{json}->{subscriptions} = \@rows;
    $self->{json}->{name} = $name;
    $self->{json}->{msg} = __x('Subscribing server as name {name}', name => $name);
}

1;
