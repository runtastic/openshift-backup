#!/bin/sh

set -eo pipefail

POSTMODERN_GPG_KEY="B9515E77"
RUBY_INSTALL_TARBAL="https://github.com/postmodern/ruby-install/archive/v${RUBY_INSTALL_VERSION}.tar.gz"
RUBY_INSTALL_TARBAL_ASC="https://raw.github.com/postmodern/ruby-install/master/pkg/ruby-install-${RUBY_INSTALL_VERSION}.tar.gz.asc"

# Install ruby-install
cd /tmp
curl -s -L -o ruby-install.tar.gz "$RUBY_INSTALL_TARBAL";

if [ "$RUBY_INSTALL_TARBAL_ASC" ]; then
  curl -s -L -o ruby-install.tar.gz.asc "$RUBY_INSTALL_TARBAL_ASC";
  export GNUPGHOME="$(mktemp -d)";
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$POSTMODERN_GPG_KEY";
  gpg --batch --verify ruby-install.tar.gz.asc ruby-install.tar.gz;
  rm -r "$GNUPGHOME" ruby-install.tar.gz.asc;
fi;

tar -xf ruby-install.tar.gz
cd ruby-install-${RUBY_INSTALL_VERSION}
make install
rm -rf /tmp/ruby-install*
