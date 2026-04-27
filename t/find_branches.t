#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd abs_path);
use FindBin qw($Bin);

eval { require Test::Mojo;   Test::Mojo->import;   1 }
    or plan skip_all => 'Test::Mojo not available';
eval { require Mojo::Server; Mojo::Server->import; 1 }
    or plan skip_all => 'Mojo::Server not available';

chomp( my $git_version = `git --version 2>/dev/null` );
plan skip_all => 'git not found' unless $git_version;

my $server = abs_path("$Bin/../server.pl");
plan skip_all => "server.pl not found at $server" unless -e $server;

my $orig_cwd = getcwd();
my $repo     = tempdir( CLEANUP => 1 );

# Isolate from any global/system git config on the dev's machine.
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';
local $ENV{HOME}              = $repo;

# The app registers Mojolicious::Plugin::Cron at startup. The cron tick is
# irrelevant to what's under test, so stub the plugin in @INC to avoid a hard
# CPAN dependency for running tests locally.
$INC{'Mojolicious/Plugin/Cron.pm'} = __FILE__;
{
    package Mojolicious::Plugin::Cron;
    use Mojo::Base 'Mojolicious::Plugin';
    sub register { }
}

# Load the app before chdir — Mojo::Server::load_app calls FindBin->again,
# which fails if cwd has changed since the test script started.
my $app = Mojo::Server->new->load_app($server);

chdir $repo or die "chdir $repo: $!";

run_git( 'init', '-q' );
run_git( 'config', 'user.email', 'test@example.com' );
run_git( 'config', 'user.name',  'Test' );
run_git( 'commit', '--allow-empty', '-q', '-m', 'initial' );
chomp( my $base = `git rev-parse HEAD` );

run_git( 'commit', '--allow-empty', '-q', '-m', 'Bug 12345: Add feature' );
chomp( my $bug_commit = `git rev-parse HEAD` );

run_git( 'commit', '--allow-empty', '-q', '-m', 'Bug 99999: Unrelated' );
chomp( my $unrelated = `git rev-parse HEAD` );

# Fake remote-tracking refs.
# Two bywater branches contain the bug, one does not, and a differently
# prefixed branch contains the bug but should be filtered out by shortname.
run_git( 'update-ref', 'refs/remotes/origin/bywater-v22.11', $bug_commit );
run_git( 'update-ref', 'refs/remotes/origin/bywater-v23.05', $bug_commit );
run_git( 'update-ref', 'refs/remotes/origin/bywater-v24.05', $base );
run_git( 'update-ref', 'refs/remotes/origin/acme-v22.11',    $bug_commit );

my $t = Test::Mojo->new($app);

# Default shortname 'bywater' — expect the two bywater branches that
# actually contain the bug commit, sorted descending by version.
$t->get_ok('/12345')->status_is(200)
  ->json_is( [ 'bywater-v23.05', 'bywater-v22.11' ] );

# Explicit shortname selects a different prefix.
$t->get_ok('/12345/acme')->status_is(200)->json_is( ['acme-v22.11'] );

# Bug with no matching commits returns an empty list.
$t->get_ok('/77777')->status_is(200)->json_is( [] );

chdir $orig_cwd;

done_testing();

sub run_git {
    my @args = @_;
    system( 'git', @args ) == 0 or die "git @args failed: $?";
}
