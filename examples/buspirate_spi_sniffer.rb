$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
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

  print "entering binary SPI mode...\t"
  if buspirate.switch_mode(BusPirate::Mode::SPI)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "setting speed...\t\t"
  if buspirate.spi_set_speed(BusPirate::SPI::SPEED_30KHZ)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "setting configuration...\t"
  if buspirate.spi_set_config(BusPirate::SPI::PIN_OUTPUT_33V, BusPirate::SPI::CLOCK_IDLE_LOW, BusPirate::SPI::CLOCK_EDGE_IDLE_TO_ACTIVE, BusPirate::SPI::SAMPLE_TIME_MIDDLE)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "configuring peripherals...\t"
  if buspirate.config_peripherals(true, false, true, false)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "starting sniffer..."
  puts ""

  bytes_expected = 0
  buspirate.spi_sniffer(false) do |byte|
    if bytes_expected == 2
      print "0x#{byte.to_s(16)}"
      bytes_expected = 1
    elsif bytes_expected == 1
      puts " :: 0x#{byte.to_s(16)}"
      bytes_expected = 0
    elsif byte == 91 # [
      puts "CS enable"
    elsif byte == 93 # ]
      puts "CS disable"
    elsif byte == 92 # \
      bytes_expected = 2
    end
  end

rescue => e
  puts "Error: #{e}"
ensure
  buspirate.port.putc 0x01 # this properly ends the sniffer mode when CTRL-C is received
  buspirate.close unless buspirate.nil?
end
