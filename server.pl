#!/usr/bin/perl

use Mojolicious::Lite -signatures;
use List::Util qw(uniq);
use Data::Dumper;

app->config( hypnotoad => { listen => ['http://*:3000'] } );

get '/:bug/:shortname' => { shortname => 'bywater' } => sub ($c) {

    my $bug       = $c->param('bug');
    my $shortname = $c->param('shortname');

    warn "BUG: $bug";
    warn "SHORTNAME: $shortname";

    my @response = qx{git log --all --grep "Bug $bug:" --pretty=oneline};

    if ( @response ) {
        my @commits = map { ( split( ' ', $_ ) )[0] } @response;

        my @branches = map {
            map { ( split( '/', $_ ) )[1] }
              qx{git branch -r --contains $_}
        } @commits;

        warn "FOUND BRANCHES: " . Data::Dumper::Dumper( \@branches );

        # Strip whitespace from start and end of each branch name
        $_ =~ s/^\s+|\s+$//g for @branches;

        if (@branches) {
            @branches =
              uniq sort { ( split( '-v', $b ) )[1] cmp( split( '-v', $a ) )[1] }
              @branches;

            @branches = grep( /^$shortname/, @branches );
        }

        warn "RETURNING: " . Data::Dumper::Dumper( \@branches );

        $c->render( json => \@branches );
    } else {
        $c->render( json => [] );
    }
};

plugin Cron => (
    '0 * * * *' => sub {
        qx{cd /kohaclone && git fetch --all};
    }
);

app->start;
