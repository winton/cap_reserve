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

    task :reserve do
      ENV['RESERVE_ENV'] = 'staging'
      ENV['RESERVE_URL'] = 'http://localhost:3000'
      maitre_d
   	end

   	before "deploy", "reserve"

Use It
------

Reserve your environment for 10 minutes:

    cap deploy RESERVE=10

Force the deploy even if reserved:

    cap deploy FORCE=1

Destroy the reservation:

    cap deploy DESTROY=1

You can also reserve without deploying:

    cap reserve RESERVE=10

How it Works
------------

The `reserve` cap task looks for the following `ENV` variables:

    ENV['DESTROY']      # Destroy reservation
    ENV['FORCE']        # Force deploy
    ENV['RESERVE']      # Minutes to reserve environment
    ENV['RESERVE_ENV']  # Name of deploy environment
    ENV['RESERVE_URL']  # URL to your maitre_d server
    ENV['USER']         # Name of user
 
 In the example above, we use the `setup_reserve` cap task to set up the `RESERVE_ENV` and `RESERVE_URL` variables.