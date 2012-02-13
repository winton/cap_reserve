gem 'yajl-ruby', '= 1.0.0'

require 'open-uri'
require 'uri'
require 'yajl'

$:.unshift File.dirname(__FILE__)

class String

  # Colors

  def blue
    "\e[34m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end

  def red
    "\e[31m#{self}\e[0m"
  end

  def yellow
    "\e[33m#{self}\e[0m"
  end
end

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :maitre_d do

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

    desc "Reserve environment using RESERVE=minutes"
    task :default do
      begin
        env, user, time, force, url, destroy, branch =
          ENV['RESERVE_ENV'], ENV['USER'], ENV['RESERVE'], ENV['FORCE'], ENV['RESERVE_URL'], ENV['DESTROY'], ENV['BRANCH']

        help = <<-HELP
FORCE=1 to deploy anyway
DESTROY=1 to deploy and destroy reservation
HELP

        create = lambda do |params|
          if time
            get.call("#{url}/reservations/create", {
              :environment => env, :user => user, :seconds => time.to_i * 60, :branch => branch
            }.merge(params))
            puts "\n#{"Reservation created".green}: #{"#{user}@#{env}".yellow} for #{"#{time.to_i} minutes".yellow}\n\n"
          elsif destroy
            res = get.call("#{url}/reservations/destroy", :environment => env)
            if res['status'] == 'reserved'
              puts "\n#{"Reservation destroyed".green}: #{"#{res['user']}@#{env}".yellow} (#{expires_to_string.call(Time.at(res['expires'])).yellow} left)\n\n"
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
              puts "\n#{"Reservation exists".red}: #{"#{res['user']}@#{env}".yellow} (#{expires_to_string.call(Time.at(res['expires'])).yellow})\n#{help}\n"
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

    desc "Show environment reservation status"
    task :available do
      puts "\n"
      url, envs = ENV['RESERVE_URL'], ENV['RESERVE_ENVS']
      envs.split(/\s/).each do |env|
        res = get.call("#{url}/reservations/show", :environment => env)
        puts "#{env.yellow} is #{res['status'] == 'available' ? "available".green : "reserved".red}"
        if res['status'] == 'reserved'
          puts "  #{"#{res['user']}@#{env}".yellow} for #{expires_to_string.call(Time.at(res['expires'])).yellow} at branch #{res['branch'].yellow}"
        end
        puts "\n"
      end
    end
  end
end
