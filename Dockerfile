FROM openshift/origin-cli:v3.10

ARG RUBY_INSTALL_VERSION=0.7.0
ARG RUBY_KIND=ruby
ARG RUBY_VERSION=2.5.3

LABEL maintainer="Gabriele Vassallo <gabriele.vassallo@runtastic.com>" \
      summary="Openshift resource state backup to git"

RUN INSTALL_PKGS="curl openssl openssh git bash gcc make automake bzip2 zlib-devel libyaml-devel openssl-devel" && \
    yum install -y ${INSTALL_PKGS}

WORKDIR /opt/app
ADD install-ruby-install.sh /opt/app
RUN /opt/app/install-ruby-install.sh && rm /opt/app/install-ruby-install.sh

ENV GIT_SERVER="github.com gitlab.com bitbucket.org codebasehq.com" \
    GIT_SERVER_PORT=22 \
    PATH=/opt/rubies/$RUBY_KIND-$RUBY_VERSION/bin:/opt/app/bin:$PATH

# Install ruby
RUN ruby-install --no-install-deps --cleanup $RUBY_KIND $RUBY_VERSION -- --disable-install-rdoc
RUN gem update --system --silent && \
    gem install bundler --force

ADD Gemfile Gemfile.lock /opt/app/
RUN bundle install -j 8

ADD . /opt/app

RUN mkdir -p ~/.ssh/ && \
    ssh-keyscan -p $GIT_SERVER_PORT -t rsa,dsa $GIT_SERVER >> ~/.ssh/known_hosts

ENTRYPOINT ["sh", "-c"]
CMD ["openshift_backup backup && openshift_backup push"]
