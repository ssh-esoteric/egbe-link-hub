# frozen_string_literal: true

class LinkStatus
  def initialize(redis, secret, wait: 0)
    @redis = redis
    @secret = secret
    @wait = wait.to_i

    @host = fetch_peer :host
    @host_changed = false

    @guest = fetch_peer :guest
    @guest_changed = false
  end

  def host_id; @host[:id]; end
  def guest_id; @guest[:id]; end

  def host; @host; end
  def guest; @guest; end

  private def fetch_peer(key)
    tmp = @redis.get "#@secret/#{key}"
    if tmp
      JSON.parse tmp, symbolize_names: true
    else
      peer = {
        id: 0,
        cycles: 0,
        serial: -1,
        infrared: 0,
      }
      @redis.set "#@secret/#{key}", JSON.generate(peer)
      peer
    end
  end

  private def update_peer(peer, obj)
    if peer[:id].zero?
      peer[:id] = obj[:id].to_i
    else
      if obj['cycles']
        peer[:cycles] = obj['cycles'].to_i
        peer[:serial] = obj['serial'].to_i
        peer[:infrared] = obj['infrared'].to_i
      else
        peer[:cycles] = obj[:cycles].to_i
        peer[:serial] = obj[:serial].to_i
        peer[:infrared] = obj[:infrared].to_i
      end
    end
  end

  def update_host(obj)
    update_peer @host, obj
    @host_changed = true
  end

  def update_guest(obj)
    update_peer @guest, obj
    @guest_changed = true
  end

  def to_json(*)
    {
      secret: @secret,
      host: @host,
      guest: @guest,
    }.to_json
  end

  private def commit_peer(key, peer, other)
    peer_key = "#@secret/#{peer[:id]}"
    other_key = "#@secret/#{other[:id]}"

    json = JSON.generate peer
    @redis.set "#@secret/#{key}", json

    @redis.del other_key
    @redis.rpush other_key, json

    @redis.del peer_key

    fresh = nil
    fresh = @redis.blpop peer_key, timeout: @wait unless @wait.zero?
    if fresh
      JSON.parse(fresh.second, symbolize_names: true)
    else
      nil
    end
  end

  def commit
    if @host_changed
      fresh = commit_peer :host, @host, @guest
      @guest = fresh if fresh

      if @guest[:id] > 0
        ActionCable.server.broadcast "#@secret/#{@guest[:id]}", to_json
      end
    elsif @guest_changed
      fresh = commit_peer :guest, @guest, @host
      @host = fresh if fresh

      if @host[:id] > 0
        ActionCable.server.broadcast "#@secret/#{@host[:id]}", to_json
      end
    end
  end
end
