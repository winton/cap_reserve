CapReserve
==========

Uses a `maitre_d` server to reserve time on deploy environments.

Requirements
------------

<pre>
gem install cap_reserve
</pre>

Setup
-----

You must have a [maitre_d](https://github.com/winton/maitre_d) server running first.

### deploy.rb

    require 'cap_reserve'

    task :setup_reserve do
      ENV['RESERVE_ENV'] = 'staging'
      ENV['RESERVE_URL'] = 'http://localhost:3000'
      reserve
   	end

   	before "deploy", "setup_reserve"

Use It
------

Reserve your environment for 10 minutes:

    cap deploy RESERVE=10

Force the deploy even if reserved:

    cap deploy FORCE=1

How it Works
------------

The `reserve` cap task looks for the following `ENV` variables:

    ENV['FORCE']        # Force deploy
    ENV['RESERVE']      # Minutes to reserve environment
    ENV['RESERVE_ENV']  # Name of deploy environment
    ENV['RESERVE_URL']  # URL to your maitre_d server
    ENV['USER']         # Name of user
 
 In the example above, we use the `setup_reserve` cap task to set up these variables.