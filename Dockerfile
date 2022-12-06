FROM perl:5.32
RUN cpanm Mojolicious Mojolicious::Plugin::Cron Data::Dumper
RUN git clone https://github.com/bywatersolutions/bywater-koha.git /kohaclone && cd /kohaclone && git remote add future https://github.com/bywatersolutions/bywater-koha-future.git && git fetch --all
WORKDIR /kohaclone
COPY server.pl .
COPY public .
CMD ["hypnotoad", "-f", "server.pl"]
