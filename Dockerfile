ARG RUBY_VERSION=7.0
FROM ruby:$RUBY_VERSION-slim

# Installation des dépendances système (PostgreSQL client, compilateurs)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev git pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT="true" \
    RAILS_SERVE_STATIC_FILES="true"

# Installation des Gems Ruby
COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform x86_64-linux && \
    bundle install && \
    bundle exec rails assets:precompile && \
    bundle exec rails assets:clean && \
    bundle exec rails db:migrate && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

# Copie du code de l'application
COPY . .

# Précompilation des assets (Bootstrap / Sprockets / Importmap) sans clé secrète réelle
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Google Cloud Run écoute par défaut sur le port 8080
EXPOSE 8080
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]