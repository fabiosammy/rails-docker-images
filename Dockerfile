FROM ruby:2.6.2
MAINTAINER fabiosammy <fabiosammy@gmail.com>

# Install apt based dependencies required to run Rails as
# well as RubyGems. As the Ruby image itself is based on a
# Debian image, we use apt-get to install those.
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  openssh-server \
  bison \
  libgdbm-dev \
  ruby \
  locales \
  mysql-client \
  postgresql-client \
  sqlite3 \
  nodejs \
  sudo \
  cmake \
  graphviz \
  rsync \
  ssh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Use en_US.UTF-8 as our locale
RUN locale-gen en_US.UTF-8 && \
  localedef -c -i en_US -f UTF-8 en_US.UTF-8 
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# skip installing gem documentation
RUN chmod 777 /usr/local/bundle && mkdir -p /usr/local/etc && { echo 'install: --no-document'; echo 'update: --no-document'; } >> /usr/local/etc/gemrc

# SSH config
RUN mkdir /var/run/sshd \
  && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && echo "export VISIBLE=now" >> /etc/profile \
  && echo 'root:root' | chpasswd

ENV NOTVISIBLE="in users profile" \
  HOME=/home/devel \
  APP=/var/www/app

# ADD an user
RUN adduser --disabled-password --gecos '' devel \
  && usermod -a -G sudo devel \
  && usermod -a -G staff devel \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && echo 'devel:devel' | chpasswd

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
RUN mkdir -p $HOME \
  && mkdir -p $APP \
  && chown -R devel:devel $HOME \
  && chown -R devel:devel $APP

RUN echo "APP=${APP}" | sudo tee -a /etc/environment && \
  echo "BUNDLE_APP_CONFIG=${BUNDLE_APP_CONFIG}" | sudo tee -a /etc/environment && \
  echo "BUNDLE_PATH=${BUNDLE_PATH}" | sudo tee -a /etc/environment && \
  echo "GEM_HOME=${GEM_HOME}" | sudo tee -a /etc/environment && \
  echo "GEM_PATH=${GEM_PATH}" | sudo tee -a /etc/environment && \
  echo "PATH=${PATH}" | sudo tee -a /etc/environment

USER devel:devel
WORKDIR $APP

# Install bundler to user and update path
RUN gem install bundler -v 1.17.3 \
  && gem install rails -v 5.2.3 \
  && rails new ~/my-app \
  && rm -rf ~/my-app

# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
#COPY Gemfile Gemfile.lock ./
#RUN bundle install --retry 5

# Copy the main application.
#COPY . ./

# Expose ports to the Docker host, so we can access it
# from the outside.
# SSH - 22
EXPOSE 22
# Mailcatcher - 1025 and 1080
EXPOSE 1025
EXPOSE 1080
# Rails server - 3000
EXPOSE 3000
# Websocket - 9292
EXPOSE 9292

# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["/usr/bin/sudo", "/usr/sbin/sshd", "-D"]

