# Reports what a Servus app sees after boot. Run with: bin/rails runner script/check.rb
def report(label)
  puts "#{label.ljust(46)} #{yield}"
rescue NoMethodError => error
  puts "#{label.ljust(46)} NoMethodError: #{error.message.lines.first.strip}"
end

puts "Servus #{Servus::VERSION}, Rails #{Rails.version}, #{Rails.env}"
report("ActiveJob loaded after boot?") { ActiveSupport.instance_variable_get(:@loaded).fetch(:active_job, []).any? }
report("Greeting::Send::Service.call_async") { Greeting::Send::Service.call_async(name: "Ada").class }
report("Greeting::Archive::Service job queue") { Greeting::Archive::Service.servus_job_class.queue_name }
