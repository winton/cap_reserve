require File.dirname(__FILE__) + '/cap_reserve/gems'

CapReserve::Gems.activate %w(nestful)
require 'nestful'

$:.unshift File.dirname(__FILE__)

Capistrano::Configuration.instance(:must_exist).load do 

  desc "Reserve environment using RESERVE=minutes"
  task :reserve do
    env, user, time, force, url =
      ENV['RESERVE_ENV'], ENV['USER'], ENV['RESERVE'], ENV['FORCE'], ENV['RESERVE_URL']

    create = lambda do |params|
      if time
        Nestful.get("#{url}/reservations/create", :format => :json, :params => {
          :environment => env, :user => user, :seconds => time.to_i * 60
        }.merge(params))
        puts "Reservation created: #{user}@#{env} for #{time.to_i} minutes"
      elsif force
        res = Nestful.get("#{url}/reservations/destroy", :params => { :environment => env }, :format => :json)
        if res['status'] == 'reserved'
          puts "Reservation destroyed: #{res['user']}@#{env} (#{(Time.at(res['expires']) - Time.now) / 60} minutes left)"
        end
      end
    end

    if env && user
      if force
        create.call(:force => true)
      else
        res = Nestful.get("#{url}/reservations/show", :params => { :environment => env }, :format => :json)
        if res['status'] == 'reserved'
          if res['user'] == user
            create.call({})
          else
            puts "Reservation exists: #{res['user']}@#{env} for #{(Time.at(res['expires']) - Time.now) / 60} minutes"
            exit 0
          end
        else
          create.call({})
        end
      end
    end
  end
end