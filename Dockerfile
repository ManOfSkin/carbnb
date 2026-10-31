ARG RUBY_VERSION=3.1.2
FROM ruby:$RUBY_VERSION-slim

# Remplacer les dépôts obsolètes par les archives Debian et installer les dépendances (dont nodejs pour execjs/sassc)
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org\/debian-security/g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev git pkg-config nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT="true" \
    RAILS_SERVE_STATIC_FILES="true"

# Copie des fichiers de dépendances
COPY Gemfile Gemfile.lock ./

# Installation de Bundler 2.6.9
RUN gem install bundler -v 2.6.9 && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

# Copie du code de l'application
COPY . .

# Précompilation des assets (avec une vraie clé factice)
RUN SECRET_KEY_BASE=dummy_secret_key_just_for_build_purposes ./bin/rails assets:precompile

# Lancement classique et propre de Rails avec nettoyage et migration inclus
EXPOSE 8080

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && ./bin/rails db:prepare && ./bin/rails searchkick:reindex CLASS=Car && ./bin/rails server -b 0.0.0.0 -p 8080"]