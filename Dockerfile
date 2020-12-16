FROM perl:5.32
RUN cpanm Mojolicious Mojolicious::Plugin::Cron Data::Dumper
RUN git clone https://github.com/bywatersolutions/bywater-koha.git /kohaclone
WORKDIR /kohaclone
COPY server.pl .
CMD ["hypnotoad", "-f", "server.pl"]
