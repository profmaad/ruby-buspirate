require 'rubygems'
require 'buspirate'

DEFAULT_BAUDRATE = 115200
DEFAULT_DATABITS = 8
DEFAULT_STOPBITS = 1
DEFAULT_PARITY = SerialPort::NONE
DEFAULT_DEVICE = "/dev/bus_pirate"

begin
  buspirate = BusPirate.new(DEFAULT_DEVICE, DEFAULT_BAUDRATE, DEFAULT_DATABITS, DEFAULT_STOPBITS, DEFAULT_PARITY)

  buspirate.reset_console

  print "entering bitbang mode..\t\t"
  if buspirate.enter_bitbang
    puts "done"
  else
    puts "failed"
    exit
  end

  print "running short self test...\t"
  errors = buspirate.run_selftest(false)
  if errors == 0
    puts "done"
  else
    puts "failed: #{errors} errors"
  end
  errors_total = errors

  print "running long self test...\t"
  errors = buspirate.run_selftest(true)
  if errors == 0
    puts "done"
  else
    puts "failed: #{errors} errors"
  end
  errors_total += errors

  puts ""
  if errors_total == 0
    puts "\t everything's just dandy :-)"
  else
    puts "\t Bus Pirate made #{errors_total} booboos :-("
  end
  puts ""
rescue => e
  puts "Error: #{e}"
ensure
  buspirate.close unless buspirate.nil?
end
