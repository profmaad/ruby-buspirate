require 'rubygems'
require 'serialport'

DEFAULT_BAUDRATE = 115200
DEFAULT_DATABITS = 8
DEFAULT_STOPBITS = 1
DEFAULT_PARITY = SerialPort::NONE
DEFAULT_DEVICE = "/dev/bus_pirate"

class BusPirate
  attr_reader :port
  
  def initialize(device, baudrate, databits, stopbits, parity)
    @port = SerialPort.new(device, :baud => baudrate, :data_bits => databits, :stop_bits => stopbits, :parity => parity)
    throw "failed to initialize Bus Pirate on port #{device}" if @port.nil?
  end

  def close
    enter_mode_raw
    exit_bitbang
    @port.close
  end

  def reset_console
    (0..10).each do
      @port.putc 0x0d # send enter    
    end
    @port.putc '#'    
  end

  def enter_bitbang
    (0..25).each do |i|
      @port.putc 0x00

      selectResult = IO.select([@port],[],[],0.2)
      if selectResult
        result = check_for_ack("BBIO1")
        
        return true if result
      end
    end
    
    return false
  end

  def exit_bitbang
    @port.putc 0x0f
  end

  def check_for_ack(ack)
    if ack.class == String
      ack.each_byte do |ack_byte|
        read_byte = @port.readbyte
        return false if read_byte != ack_byte
      end
    elsif ack.class == Fixnum
      read_byte = @port.readbyte
      return false if read_byte != ack
    end
    
    return true
  end

  def enter_mode_raw
    @port.putc 0x00
    return check_for_ack("BBIO1")
  end

  def enter_mode_uart
    @port.putc 0b00000011
    return check_for_ack("ART1")
  end
  def uart_set_baudrate(baudrate)
    bitvalue = 0b01100000
    bitvalue += 
      case baudrate
      when 300 then 0b0000
      when 1200 then 0b0001
      when 2400 then 0b0010
      when 4800 then 0b0011
      when 9600 then 0b0100
      when 19200 then 0b0101
      when 31250 then 0b0110
      when 38400 then 0b0111
      when 57600 then 0b1000
      when 115200 then 0b1010
      end

    @port.putc bitvalue
    return check_for_ack(0x01)
  end
  def uart_set_config(pin_output, databits_parity, stopbits, idle_polarity)
    bitvalue = 0b10000000
    if pin_output
      bitvalue += 0b00010000
    end
    bitvalue += case databits_parity
                when 0 then 0b00000000
                when 1 then 0b00000100
                when 2 then 0b00001000
                when 3 then 0b00001100
                end
    if stopbits
      bitvalue += 0b00000010
    end
    if idle_polarity
      bitvalue += 0b00000001
    end

    @port.putc bitvalue
    return check_for_ack(0x01)
  end
  def uart_config_peripherals(power, pullups, aux, cs)
    bitvalue = 0b01000000
    if power
      bitvalue += 0b00001000
    end
    if pullups
      bitvalue += 0b00000100
    end
    if aux
      bitvalue += 0b00000010
    end
    if cs
      bitvalue += 0b00000001
    end

    @port.putc bitvalue
    return check_for_ack(0x01)
  end

  def uart_rx_echo(echo)
    if echo
      @port.putc 0b00000010
    else
      @port.putc 0b00000011
    end
    
    return check_for_ack(0x01)
  end
end

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
  if buspirate.enter_mode_uart
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
  if buspirate.uart_set_config(false, 0, false, false)
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
