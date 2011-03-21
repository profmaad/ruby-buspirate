#require 'rubygems'
require 'buspirate'

require 'pp'

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

  print "setting CS high...\t\t"
  if buspirate.spi_set_cs(true)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "writing value to register 0x0009...\t"
  buspirate.spi_cs_block(true) do
    pp buspirate.spi_bulk_write_read([0xf0, 0x00, 0x09, 0x23])
  end
  print "reading value from register 0x0009...\t"
  buspirate.spi_cs_block(true) do
    pp buspirate.spi_bulk_write_read([0x0f, 0x00, 0x09, 0x00])
  end

rescue => e
  puts "Error: #{e}"
ensure
  buspirate.close unless buspirate.nil?
end
