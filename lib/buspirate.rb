#
# Bus Pirarrte!
#
#http://dangerousprototypes.com/2009/10/09/bus-pirate-raw-bitbang-mode/
#require 'rubygems'
require 'serialport'
require 'bus_pirate/constants'

class BusPirate

  attr_reader :port

  def initialize(device, baudrate = 115200, databits = 8, stopbits = 1, parity = SerialPort::NONE)
    @port = SerialPort.new(device, :baud => baudrate, :data_bits => databits, :stop_bits => stopbits, :parity => parity)
    throw "failed to initialize Bus Pirate on port #{device}" if @port.nil?
  end

  def close
    reset_bitbang
    exit_bitbang
    @port.close
  end

  def reset_console
    (0..10).each { @port.putc 0x0d } # send enter
    @port.putc '#'
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

  def clear_buffer
    selectResult = IO.select([@port],[],[],0.2)
    if selectResult
      @port.readbyte
      clear_buffer
    end
  end

  #
  # Start binary connection
  #
  def enter_bitbang
    loop do
      @port.putc 0b0000000

      selectResult = IO.select([@port],[],[],0.2)
      if selectResult && check_for_ack("BBIO1")
        clear_buffer
        return true
      end
    end

    return false
  end

  def do_switch_mode(mode)
    @port.putc bitvalue
    return check_for_ack(ack)
  end

  def switch_mode(byte, ack)
    case mode
    when Mode::RESET   then do_switch_mode(0b00000000, "BBIO1")
    when Mode::SPI     then do_switch_mode(0b00000001, "SPI1")
    when Mode::I2C     then do_switch_mode(0b00000010, "I2C1")
    when Mode::UART    then do_switch_mode(0b00000011, "ART1")
    when Mode::ONEWIRE then do_switch_mode(0b00000100, "1W01")
    when Mode::RAWWIRE then do_switch_mode(0b00000101, "RAW1")
    else
      return false
    end
  end

  def run_selftest(long)
    @port.putc(long ? 0b00010001 : 0b00010000)
    errors = @port.readbyte

    @port.putc 0xFF # leave selftest mode
    return -1 unless check_for_ack(0x01)
    return errors
  end

  def disable_pwm
    @port.putc 0b00010011
    return check_for_ack(0x01)
  end

  def calculate_pwm_bytes(prescaler, pwm_period, duty_cycle_in_percent)
    # adapted from this script: http://codepad.org/qtYpZmIF
    tcy = 2.0/FOSC.to_f
    pry = pwm_period/(tcy*prescaler)
    pry -= 1
    ocr = pry * duty_cycle_in_percent

    bytes = Array.new

    bytes.push {1 => 0, 8 => 1, 64 => 2, 256 => 3}[prescaler]

    bytes.push((ocr.to_i >> 8) & 0xFF)
    bytes.push ocr.to_i & 0xFF
    bytes.push((pry.to_i >> 8) & 0xFF)
    bytes.push pry.to_i & 0xFF

    return bytes
  end

  def setup_pwm(prescaler, pwm_period, duty_cycle_in_percent)
    bytes = calculate_pwm_bytes(prescaler, pwm_period, duty_cycle_in_percent)

    @port.putc 0b00010010
    bytes.each do |byte|
      @port.putc byte
    end

    return check_for_ack(0x01)
  end

  # internal!
  def get_adc_voltage
    high_byte = @port.readbyte
    low_byte = @port.readbyte

    adc_value = (high_byte << 8) + low_byte
    voltage = (adc_value.to_f/1024.to_f)*6.6

    return voltage
  end

  def read_adc
    @port.putc 0b00010100

    return get_adc_voltage
  end

  def read_adc_continuous
    @port.putc 0b00010101

    loop do
      p get_adc_voltage
    end
  end

  def configure_pins(aux, mosi, clk, miso, cs)
    bitvalue = 0b01000000
    bitvalue += 0b00010000 if aux == PinMode::INPUT
    bitvalue += 0b00001000 if mosi == PinMode::INPUT
    bitvalue += 0b00000100 if clk == PinMode::INPUT
    bitvalue += 0b00000010 if miso == PinMode::INPUT
    bitvalue += 0b00000001 if cs == PinMode::INPUT

    @port.putc bitvalue
    return @port.readbyte
  end

  def set_pins(power, pullup, aux, mosi, clk, miso, cs)
    bitvalue = 0b10000000
    bitvalue += 0b01000000 if power
    bitvalue += 0b00100000 if pullup
    bitvalue += 0b00010000 if aux
    bitvalue += 0b00001000 if mosi
    bitvalue += 0b00000100 if clk
    bitvalue += 0b00000010 if miso
    bitvalue += 0b00000001 if cs

    @port.putc bitvalue
    return @port.readbyte
  end

  def config_peripherals(power, pullups, aux, cs)
    bitvalue = 0b01000000
    bitvalue += 0b00001000 if power
    bitvalue += 0b00000100 if pullups
    bitvalue += 0b00000010 if aux
    bitvalue += 0b00000001 if cs

    @port.putc bitvalue
    return check_for_ack(0x01)
  end

  def uart_set_baudrate(baudrate)
    register_value = ((((FOSC.to_f/UART_CLOCK_DIVIDER.to_f)/baudrate.to_f)/4)-1).round
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

  def uart_rx_echo(echo)
    @port.putc(echo ? 0b00000010 : 0b00000011)

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

  def spi_set_cs(cs)
    @port.putc(cs ? 0b00000011 : 0b00000010)

    return check_for_ack(0x01)
  end

  def spi_set_speed(speed)
    bitvalue = 0b01100000 + speed

    @port.putc bitvalue
    return check_for_ack(0x01)
  end

  def spi_set_config(pin_mode, clock_idle, clock_edge, sample_time)
    bitvalue = 0b10000000
    bitvalue += pin_mode
    bitvalue += clock_idle
    bitvalue += clock_edge
    bitvalue += sample_time

    @port.putc bitvalue
    return check_for_ack(0x01)
  end

  def spi_bulk_write_read(data)
    data_read = []

    blocks = data.length.divmod(16)

    position = 0
    (1..blocks[0]).each do
      @port.putc 0b00011111
      return data_read unless check_for_ack(0x01)

      (0..15).each do
        @port.putc data[position]
        data_read.push @port.readbyte
        position += 1
      end
    end

    if blocks[1] > 0
      bitvalue = 0b00010000
      bitvalue += blocks[1]-1
      @port.putc bitvalue
      return data_read unless check_for_ack(0x01)

      (1..blocks[1]).each do
        @port.putc data[position]
        data_read.push @port.readbyte
        position += 1
      end
    end

    return data_read
  end

  def spi_write_then_read(data, num_read, without_cs)
    command = 0b00000100
    command += 0b00000001 if without_cs

    if data.class == String
      data_write = data.split(//)
    else
      data_write = data
    end

    data_read = []
    while (data_write.length > 0 || data_read.length < num_read)
      if data_write.length > 4096
        bytes_to_write = 4096
      else
        bytes_to_write = data_write.length
      end
      bytes_to_read = num_read - data_read.length
      bytes_to_read = 4096 if bytes_to_read > 4096

      write_bytes = split_int(bytes_to_write)
      read_bytes = split_int(bytes_to_read)

      @port.putc command
      @port.putc write_bytes[0]
      @port.putc write_bytes[1]
      @port.putc read_bytes[0]
      @port.putc read_bytes[1]

      bytes_to_write.times do
        @port.putc data_write.shift
      end

      select_result = IO.select([@port],[],[],10)
      if select_result
        result = check_for_ack(0x01)
        return data_read unless result
      end

      bytes_to_read.times do
        break if @port.eof?

        data_read.push @port.readbyte
      end
    end

    return data_read
  end

  def spi_cs_block(cs_idle_high)
    spi_set_cs(!cs_idle_high)
    yield
    spi_set_cs(cs_idle_high)
  end

  def spi_sniffer(sniff_all)
    command = (sniff_all ? 0b00001101 : 0b00001110)

    @port.putc command
    return false unless check_for_ack(0x01)

    loop { yield @port.readbyte }
  end

  def split_int(value)
    high_byte = (value & 0xFF00) >> 8
    low_byte = value & 0x00FF

    return [high_byte,low_byte]
  end
end
