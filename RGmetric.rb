#!/usr/bin/env ruby

require 'rubygems'
require 'gmetric'
require 'optparse'

# Get Options
options = {}

option_parser = OptionParser.new do |opts|
  opts.banner = 
  'Help message of RGmetric , v 0.1
  heartbeat is not supported now.
  mcast in ganglia conf is not supported now.
  '
  
  #options[:help] = false
  #opts.on('-h','--help','') do
  #  options[:help] = true
  #end
  
  options[:version] = false
  opts.on('-V','--version','') do
    options[:version] = true
  end
  
  options[:heartbeat] = false
  opts.on('-b','--heartbeat','') do
    options[:heartbeat] = true
  end
  
  options[:debug] = false
  opts.on('-z','--debug','') do
    options[:debug] = true
  end
  
  opts.on('-n NAME', '--name=NAME', 'Name of the metric') do |value|
      options[:name] = value
  end

  opts.on('-v VALUE', '--value=VALUE', 'Value of the metric') do |value|
      options[:value] = value
  end

  opts.on('-g GROUP', '--group=GROUP', 'Group of the metric') do |value|
      options[:group] = value
  end

  opts.on('-c CONF', '--conf=CONF', "The configuration file to use for finding send channels (default='/etc/ganglia/gmond.conf')") do |value|
      options[:conf] = value || '/etc/ganglia/gmond.conf'
  end

  opts.on('-t TYPE', '--type=TYPE', 'string|int8|uint8|int16|uint16|int32|uint32|float|double') do |value|
      options[:type] = value
  end

  opts.on('-u UNITS', '--units=UNITS', "Unit of measure for the value e.g. Kilobytes, Celcius (default='')") do |value|
      options[:units] = value || ''
  end

  opts.on('-s SLOPE', '--slope=SLOPE', "Either zero|positive|negative|both  (default='both')") do |value|
      options[:slope] = value || 'both'
  end

  opts.on('-x TMAX', '--tmax=TMAX', "The maximum time in seconds between gmetric calls (default='60')") do |value|
      options[:tmax] = value || 60
  end

  opts.on('-d DMAX', '--dmax=DMAX', "The lifetime in seconds of this metric  (default='0')") do |value|
      options[:dmax] = value || 0
  end

  opts.on('-S SPOOF', '--spoof=SPOOF', "IP address and name of host/device (colon separated) we are spoofing  (default='')") do |value|
      options[:spoof] = value || ''
  end

end.parse!


# Remove comments in the gmond conf
cfg_path = options[:conf] || '/etc/ganglia/gmond.conf'
cfg_ok = ''

commented = false
IO.read(cfg_path).each do |lines|
	case lines
  when /^.*'.*(\/\*|\*\/|\/\*.*\*\/|#).*'.*$/ || \
        /^.*".*(\/\*|\*\/|\/\*.*\*\/|#).*".*$/
    cfg_ok << lines
	when /^.*\/\*.*\*\/.*$/
    if commented == false
	   cfg_ok << lines.gsub(/\/\*.*\*\//,'')
    end
	when /^.*\*\/.*$/
		if commented == false 
			puts "ERROR : commented : #{commented} , matched: */ , lines: #{lines}"
    else
      cfg_ok << lines.gsub(/^.*\*\//,'')
		end
		# else commented this lines
    commented = false
	when /^.*\/\*.*$/
    if commented == false
		  cfg_ok << lines.gsub(/\/\*.*$/,'')
      commented = true
    end
  when /^.*#.*$/
    if commented == false
      cfg_ok << lines.gsub(/#.*$/,'')
    end
  else
    if commented == false
      cfg_ok << lines
    end
	end
end

# get server's host\port\ttl from conf
host = port = ttl = ''
send_channel = false
cfg_ok.each do |lines|
  case lines
  when /^.*(udp_send_channel|udp_send_channel.*\{).*$/
    send_channel = true
  when /^.*host.*=.*$/
    if send_channel == true
      host = lines.gsub(/^.*host.*=/,'').chomp.strip
    end
  when /^.*port.*=.*$/
    if send_channel == true
      port = lines.gsub(/^.*port.*=/,'').chomp.strip
    end
  when /^.*ttl.*=.*$/
    if send_channel == true
      ttl = lines.gsub(/^.*ttl.*=/,'').chomp.strip
    end
  end
end

if options[:debug]
  puts "Options:#{options.inspect}"
  puts "gmond configuration:#{cfg_ok}"
  puts "Gmond/Gmetric Host\\Port\\ttl:"
  puts host,port,ttl
end

# Send data
Ganglia::GMetric.send( "#{host}", "#{port}", {
  :group => "#{options[:group]}",
  :name => "#{options[:name]}",
  :units => "#{options[:units]}",
  :type => "options[:type]",     # unsigned 8-bit int
  :value => options[:value],       # value of metric
  :tmax => options[:tmax],          # maximum time in seconds between gmetric calls
  :dmax => options[:dmax]          # lifetime in seconds of this metric
})

