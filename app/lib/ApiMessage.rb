# frozen_string_literal: true

class ApiMessage
  attr_reader :code, :offset, :xfer

  def self.disconnected
    new 'd', 0, 0
  end

  def self.parse(msg)
    match = /([cdxi]) ([0-9]+) ([0-9]+)/.match msg
    raise "Unable to parse message" if match.nil?

    new *match.captures
  end

  def initialize(code, offset, xfer)
    self.code = code
    self.offset = offset
    self.xfer = xfer
  end

  def code=(value)
    @code = value.to_s[0]
  end

  def offset=(value)
    @offset = value.to_i
  end

  def xfer=(value)
    @xfer = value.to_i % 256
  end

  def to_s
    "#@code #@offset #@xfer"
  end
end
