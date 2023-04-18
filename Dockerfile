FROM ruby:2.5.3 as hyrax-base

RUN apt-get update -qq && \
    apt-get -y install apt-transport-https && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update -qq && \
    apt-get install -y \
      build-essential \
      cmake \
      exiftool \
      ffmpeg \
      ghostscript \
      imagemagick \
      libpq-dev \
      libreoffice \
      libvips-dev \
      netcat \
      nodejs \
      screen \
      unzip \
      vim \
      yarn \
      zip \
      && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    yarn config set no-progress && \
    yarn config set silent

# If changes are made to fits version or location,
# amend `LD_LIBRARY_PATH` in docker-compose.yml accordingly.
RUN mkdir -p /app/fits && \
    curl -fSL -o /app/fits/fits-latest.zip https://github.com/harvard-lts/fits/releases/download/1.4.0/fits-latest.zip && \
    cd /app/fits && unzip fits-latest.zip && chmod +X /app/fits/fits.sh && \
    cp -r /app/fits/* /usr/local/bin/

COPY ./ops/bin /app/samvera
ENV PATH="/app/samvera:$PATH"
ENV RAILS_ROOT="/app/samvera/hyrax-webapp"

RUN mkdir /opt/csv
RUN mkdir -p /app/samvera/hyrax-webapp
WORKDIR /app/samvera/hyrax-webapp
ADD Gemfile /app/samvera/hyrax-webapp/Gemfile
ADD Gemfile.lock /app/samvera/hyrax-webapp/Gemfile.lock
# for engine dev only
#ADD vendor/engines/bulkrax /app/samvera/hyrax-webapp/vendor/engines/bulkrax

ENV BUNDLE_JOBS=4
RUN cd /app/samvera/hyrax-webapp && ls -l && bundle install
ADD . /app/samvera/hyrax-webapp
RUN npm install shx --global && cd /app/samvera/hyrax-webapp && yarn install
RUN cd /app/samvera/hyrax-webapp && NODE_ENV=production DB_ADAPTER=nulldb bundle exec rake assets:clobber assets:precompile && ln -s /app/samvera/branding /app/samvera/hyrax-webapp/public/branding
EXPOSE 3000

ENTRYPOINT ["hyrax-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]

FROM hyrax-base as hyrax-worker
ENV MALLOC_ARENA_MAX=2
CMD bin/worker
