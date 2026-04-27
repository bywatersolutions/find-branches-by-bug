FROM perl:5.32
COPY cpanfile /tmp/cpanfile
RUN cpanm --notest --installdeps /tmp/
RUN git clone https://github.com/bywatersolutions/bywater-koha.git /kohaclone && cd /kohaclone && git remote add future https://github.com/bywatersolutions/bywater-koha-future.git && git fetch --all
WORKDIR /kohaclone
COPY server.pl .
COPY public ./public
CMD ["hypnotoad", "-f", "server.pl"]
