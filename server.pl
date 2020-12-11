#!/usr/bin/perl

use Mojolicious::Lite;

get '/:bug' => sub {
    my ($c) = @_;

    my $bug = $c->param('bug');

    my @response = qx{git log --all --grep "Bug $bug" --pretty=oneline};

    my @commits = map { ( split( ' ', $_ ) )[0] } @response;

    my @branches = map {
        map { ( split( '/', $_ ) )[1] } qx{git branch -r --contains $_}
    } @commits;

    $_ =~ s/^\s+|\s+$//g for @branches;

    @branches =
      sort { ( split( '-v', $b ) )[1] cmp( split( '-v', $a ) )[1] } @branches;

    $c->render( json => \@branches );
};

plugin Cron => ( '0 * * * *' => sub {
    qx{cd /kohaclone && git fetch --all};
});

app->start;
