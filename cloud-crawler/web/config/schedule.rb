pwd = File.expand_path File.dirname(__FILE__)
log_dir = File.expand_path "#{pwd}/../logs"
scripts_dir = File.expand_path "#{pwd}/../scripts"


every 1.day, :at => '4:30 am' do
   command "puts \'hello world\'", :output => "#{log_dir}/whenever.log"
end

