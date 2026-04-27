requires 'Mojolicious';
requires 'Mojolicious::Plugin::Cron';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Mojo';
};
