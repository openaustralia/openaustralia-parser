# Local Development

The `local_dev` folder contains a [Vagrant virtual machine](https://www.vagrantup.com/docs)
that helps to set up a local development environment.

The vagrant provisioning sets up some parts of the development environment.

- Installs rbenv to manage Ruby


Other steps need to be done manually.

- Installing the required Ruby version
- Installing the Gems
- Running the local development server 


These are the steps to create a local development environment.

Bring up the vagrant VM, then SSH into the vagrant VM.

    $ vagrant up
    $ vagrant ssh

Check that rbenv is installed.

    $ ~/rbenv-doctor.sh

In the vagrant VM, change to the source code directory.
Install the ruby version defined in `.ruby-version`.

    $ cd /opt/source
    $ rbenv install

Install the version of bundler that was used to create `Gemfile.lock`.
Check in the file for `BUNDLED WITH`.
Ensure the rbenv shim for `bundle` is available and up to date.

    $ gem install bundler -v 2.1.4
    $ rbenv rehash

Install the gems.

    $ bundle install
    $ rbenv rehash

Run the tests.

    $ dos2unix **/*.rb
    $ dos2unix *file
    $ bundle exec rake
    $ bundle exec ./parse-members.rb --no-load
    $ bundle exec ./postcodes.rb --no-load
    $ bundle exec ./parse-abs.rb
    $ bundle exec rubocop
