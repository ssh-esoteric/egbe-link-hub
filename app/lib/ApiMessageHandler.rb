# frozen_string_literal: true

class ApiMessageHandler
  attr_reader :link_id, :role, :req, :rsp

  def initialize(redis, link_id, role, req = nil)
    @redis = redis
    @link_id = link_id.to_s # TODO: Validate syntax for redis?
    case role
    when 'guest', 'host', 'sync'
      @role = role
    else
      raise "Invalid role: #{role}"
    end
    @req = req
    @rsp = nil
  end

  def rsp
    @rsp ||= send("rsp_#@role".to_sym) || ApiMessage.disconnected
  end

  private

  def msg_push(key, msg)
    length = @redis.rpush key, msg.to_s
  end

  def msg_pop(key)
    value = @redis.blpop key, timeout: 10
    value ? ApiMessage.parse(value.second) : nil
  end

  def rsp_xfer(queue, other)
    if @req # PUT request
      length = msg_push other, @req.to_s

      sleep 0.15 if length > 5 # TODO: Very rough heuristic

      rsp = @req.dup
    else
      rsp = msg_pop queue
    end

    rsp
  end

  def rsp_guest
    rsp_xfer "#@link_id/guest", "#@link_id/host"
  end

  def rsp_host
    rsp_xfer "#@link_id/host", "#@link_id/guest"
  end

  def rsp_sync
    syn = "#@link_id/syn"
    ack = "#@link_id/ack"
    msg = @req.to_s

    @redis.set syn, msg, nx: true, ex: 10
    value = @redis.get syn

    if value == msg
      # We're the host; wait for the guest
      msg_pop ack
      @redis.del syn
      @redis.del ack
      @redis.del "#@link_id/guest"
      @redis.del "#@link_id/host"
    else
      msg_push ack, msg
    end

    ApiMessage.parse value
  end
end
