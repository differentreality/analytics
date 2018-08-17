#!/bin/bash
# This file is meant to be executed via systemd.
source /usr/local/rvm/scripts/rvm
source /etc/profile.d/rvm.sh
export ruby_ver=$(rvm list default string)

export CONFIGURED=yes
export TIMEOUT=50
export APP_ROOT=/home/rails/analytics
export RAILS_ENV="production"
# export GEM_HOME="/home/rails/analytics/vendor/bundle"
export GEM_HOME="/home/rails/analytics/vendor/bundle/ruby/2.4.0"
export GEM_PATH="/home/rails/analytics/vendor/bundle/ruby/2.4.0:/usr/local/rvm/gems/${ruby_ver}:/usr/local/rvm/gems/${ruby_ver}@global"
export PATH="/home/rails/analytics/vendor/bundle/ruby/2.4.0/bin:/usr/local/rvm/gems/${ruby_ver}/bin:${PATH}"

# Passwords
export SECRET_KEY_BASE=144567afe49b6f5bfb5874ee0cc726059ada049bdf91341f656429d92b22e15c2ebb6d5a97009f71bf5b49382930a4d699d146d3b9894e9466f080603e8c07ed
export APP_DATABASE_PASSWORD=80cdb5437d85fa8140c953b213d2ed70

# Execute the unicorn process
bundle exec puma -e production --debug
