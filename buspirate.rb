require 'rubygems'
require 'serialport'

class BusPirate
  class Mode
    RESET = 0
    SPI = 1
    I2C = 2
    UART = 3
    ONEWIRE = 4
    RAWWIRE = 5
  end
  class UART
    PIN_OUTPUT_HIZ = 0b00000000
    PIN_OUTPUT_33V = 0b00010000
    FORMAT_8N = 0b00000000
    FORMAT_8E = 0b00000100
    FORMAT_80 = 0b00001000
    FORMAT_9N = 0b00001100
    STOPBITS_1 = 0b00000000
    STOPBITS_2 = 0b00000010
    IDLE_POLARITY_1 = 0b00000000
    IDLE_POLARITY_0 = 0b00000001    
  end

  UART_FOSC = 32000000
  UART_CLOCK_DIVIDER = 2

  attr_reader :port
  
  def initialize(device, baudrate, databits, stopbits, parity)
    @port = SerialPort.new(device, :baud => baudrate, :data_bits => databits, :stop_bits => stopbits, :parity => parity)
    throw "failed to initialize Bus Pirate on port #{device}" if @port.nil?
  end

  def close
    reset_bitbang
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

  def reset_bitbang
    switch_mode(Mode::RESET)
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

  def switch_mode(mode)
    case mode
    when Mode::RESET
      bitvalue = 0b00000000
      ack = "BBIO1"
    when Mode::SPI
      bitvalue = 0b00000001
      ack = "SPI1"
    when Mode::I2C
      bitvalue = 0b00000010
      ack = "I2C1"
    when Mode::UART
      bitvalue = 0b00000011
      ack = "ART1"
    when Mode::ONEWIRE
      bitvalue = 0b00000100
      ack = "1W01"
    when Mode::RAWWIRE
      bitvalue = 0b00000101
      ack = "RAW1"
    else
      return false
    end

    @port.putc bitvalue
    return check_for_ack(ack)
  end

  def run_selftest(long)
    if long
      @port.putc 0b00010001
    else
      @port.putc 0b00010000
    end
    errors = @port.readbyte
    
    @port.putc 0xFF # leave selftest mode
    return -1 unless check_for_ack(0x01)

    return errors
  end

  def disable_pwm
    @port.putc 0b00010011
    return check_for_ack(0x01)
  end

  def read_adc
    @port.putc 0b00010100
    high_byte = @port.readbyte
    low_byte = @port.readbyte

    adc_value = (high_byte << 8) + low_byte
    voltage = (adc_value.to_f/1024.to_f)*6.6

    return voltage
  end

  def uart_set_baudrate(baudrate)
    register_value = ((((UART_FOSC.to_f/UART_CLOCK_DIVIDER.to_f)/baudrate.to_f)/4)-1).round
    high_byte = (register_value & 0xFF00) >> 8
    low_byte = register_value & 0x00FF

    @port.putc 0b00000111
    return false unless check_for_ack(0x01)

    @port.putc high_byte
    return false unless check_for_ack(0x01)

    @port.putc low_byte
    return false unless check_for_ack(0x01)

    return true
  end
  def uart_set_config(pin_output, format, stopbits, idle_polarity)
    bitvalue = 0b10000000
    bitvalue += pin_output
    bitvalue += format
    bitvalue += stopbits
    bitvalue += idle_polarity

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

  def uart_write(data)
    blocks = data.length.divmod(16)   
    
    position = 0
    (1..blocks[0]).each do
      @port.putc 0b00011111
      return position unless check_for_ack(0x01)
      
      (0..15).each do
        @port.putc data[position]
        return position unless check_for_ack(0x01)
        position += 1
      end
    end
    
    if blocks[1] > 0
      bitvalue = 0b00010000
      bitvalue += blocks[1]-1
      @port.putc bitvalue
      return position unless check_for_ack(0x01)
      
      (1..blocks[1]).each do
        @port.putc data[position]
        return position unless check_for_ack(0x01)
        position += 1
      end
    end
    
    return position
  end

  def uart_activate_bridge_mode
    # can only be left by un- and replugging the hardware
    @port.putc 0b00001111
  end
end
