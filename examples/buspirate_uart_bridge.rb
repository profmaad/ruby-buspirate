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

  print "entering binary UART mode...\t"
  if buspirate.switch_mode(BusPirate::Mode::UART)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "setting baud rate...\t\t"
  if buspirate.uart_set_baudrate(9600)
    puts "done"
  else
    puts "failed"
    exit
  end

  print "setting configuration...\t"
  if buspirate.uart_set_config(BusPirate::UART::PIN_OUTPUT_HIZ, BusPirate::UART::FORMAT_8N, BusPirate::UART::STOPBITS_1, BusPirate::UART::IDLE_POLARITY_1)
    puts "done"
  else
    puts "failed"
    exit
  end
  
  print "configuring peripherals...\t"
  if buspirate.uart_config_peripherals(true, true, false, false)
    puts "done"
  else
    puts "failed"
    exit
  end
  
  print "starting RX echo...\t\t"
  if buspirate.uart_rx_echo(true)
    puts "done"
  else
    puts "failed"
  end

  while !buspirate.port.eof?
    puts buspirate.port.readline
  end

  print "press enter to exit"
  STDIN.getc

rescue => e
  puts "Error: #{e}"
ensure
  buspirate.close unless buspirate.nil?
end
