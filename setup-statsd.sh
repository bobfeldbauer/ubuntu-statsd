# Install pre-requisites
sudo apt-get install g++ curl libssl-dev apache2-utils git-core

# Download the Node source, compile and install it
git clone https://github.com/joyent/node.git
cd node
./configure
make
sudo make install

# Install the Node package manager for later use
curl http://npmjs.org/install.sh | sudo sh
npm install express

# Clone the statsd project
git clone https://github.com/etsy/statsd.git

# Download everything for graphite
mkdir graphite
cd graphite/
wget "http://launchpad.net/graphite/0.9/0.9.9/+download/carbon-0.9.9.tar.gz"
wget "http://launchpad.net/graphite/0.9/0.9.9/+download/whisper-0.9.9.tar.gz"
wget "http://launchpad.net/graphite/0.9/0.9.9/+download/graphite-web-0.9.9.tar.gz"
tar xzvf whisper-0.9.9.tar.gz 
tar xzvf carbon-0.9.9.tar.gz 
tar xzvf graphite-web-0.9.9.tar.gz

# Install whisper - Graphite's DB system
cd whisper-0.9.9
sudo python setup.py install
popd

# Install carbon - the Graphite back-end
cd carbon-0.9.9
python setup.py install
cd /opt/graphite/conf
cp carbon.conf.example carbon.conf

# Copy the example schema configuration file, and then configure the schema
# see: http://graphite.wikidot.com/getting-your-data-into-graphite
cp storage-schemas.conf.example storage-schemas.conf

# Install other graphite dependencies
sudo apt-get install python-cairo python-django memcached python-memcache python-ldap python-twisted apache2 libapache2-mod-python
cd ~/graphite/graphite-web-0.9.9
python setup.py install

# Copy the graphite vhost example to available sites, then link it from sites-enabled.
cp example-graphite-vhost.conf /etc/apache2/sites-available/graphite.conf
ln -s /etc/apache2/sites-available/graphite.conf /etc/apache2/sites-enabled/graphite.conf
apache2ctl restart

# Create log files manually 
/opt/graphite/storage/log/webapp
touch info.log
chmod 777 info.log
touch exception.log
chmod 777 exception.log

# Change ownership of the storage folder to the Apache user/group
sudo chown -R www-data:www-data /opt/graphite/storage/
cd /opt/graphite/webapp/graphite

# Copy the local_settings example file to create the app's settings.
# This is where both carbon federation and authentication is configured
cp local_settings.py.example local_settings.py

# Run syncdb to setup the db and prime the authentication model, if you're using the DB model.
sudo python manage.py syncdb

# Start the carbon cache
cd /opt/graphite/bin/carbon-cache.py start

# Copy the the statsd config example to create the config file, defaults are fine unless you need other ports.
cd ~/statsd
cp exampleConfig.js local.js

# Start statsd
node stats.js local.js