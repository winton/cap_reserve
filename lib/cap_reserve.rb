gem 'yajl-ruby', '= 1.0.0'

require 'open-uri'
require 'uri'
require 'yajl'

$:.unshift File.dirname(__FILE__)

Capistrano::Configuration.instance(:must_exist).load do 

  desc "Reserve environment using RESERVE=minutes"
  task :maitre_d do
    begin
      env, user, time, force, url, destroy =
        ENV['RESERVE_ENV'], ENV['USER'], ENV['RESERVE'], ENV['FORCE'], ENV['RESERVE_URL'], ENV['DESTROY']

      help = <<-HELP
  FORCE=1 to deploy anyway
  DESTROY=1 to deploy and destroy reservation
HELP

      expires_to_string = lambda do |expires|
        left = Time.at(expires) - Time.now
        if left < 60
          "#{left} seconds"
        elsif left / 60 < 60
          "#{sprintf "%.1f", left / 60} minutes"
        else
          "#{sprintf "%.1f", left / 60 / 60} hours"
        end
      end

      get = lambda do |full_url, hash|
        params = ''
        hash.each do |k, v|
          params << "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}&"
        end
        params.chop! # trailing &

        json = open("#{full_url}?#{params}").read
        Yajl::Parser.parse(json)
      end

      create = lambda do |params|
        if time
          get.call("#{url}/reservations/create", {
            :environment => env, :user => user, :seconds => time.to_i * 60
          }.merge(params))
          puts "\n\e[32mReservation created\e[0m: \e[33m#{user}@#{env}\e[0m for \e[33m#{time.to_i} minutes\e[0m\n\n"
        elsif destroy
          res = get.call("#{url}/reservations/destroy", :environment => env)
          if res['status'] == 'reserved'
            puts "\n\e[32mReservation destroyed\e[0m: \e[33m#{res['user']}@#{env}\e[0m (\e[33m#{expires_to_string.call Time.at(res['expires'])}\e[0m left)\n\n"
          end
        end
      end

      if env && user
        if destroy
          create.call({})
        elsif force
          create.call(:force => true)
        else
          res = get.call("#{url}/reservations/show", :environment => env)
          if res['status'] == 'reserved'
            puts "\n\e[31mReservation exists\e[0m: \e[33m#{res['user']}@#{env}\e[0m for \e[33m#{expires_to_string.call Time.at(res['expires'])}\e[0m\n#{help}\n"
            exit 0
          else
            create.call({})
          end
        end
      end
    rescue Exception => e
      if e.inspect.include?('SystemExit')
        exit 0
      end
    end
  end
end