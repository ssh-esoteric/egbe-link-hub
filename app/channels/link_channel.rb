# frozen_string_literal: true

class LinkChannel < ApplicationCable::Channel
  extend Forwardable

  def self.make_message(name, text, timestamp = nil)
    {
      type: :message,
      name: name,
      text: text,
      timestamp: timestamp || Time.now.strftime('%s').to_i,
    }
  end
  def_delegator self, :make_message

  def subscribed
    redis = Redis.new host: 'localhost'

    secret = params[:secret]

    if params[:chat]
      stream_from "#{secret}/chat"
      return
    end

    status = LinkStatus.new redis, secret

    next_to_sub = params[:id]
    alt_id = nil
    if status.host_id.zero?
      status.update_host({
        id: next_to_sub,
        cycles: 0,
        serial: -1,
        infrared: 0,
      })
      alt_id = status.guest_id

      msg = make_message 'System', 'Host registered with WebSockets'
      ActionCable.server.broadcast "#{secret}/chat", msg
    elsif status.guest_id.zero?
      status.update_guest({
        id: next_to_sub,
        cycles: 0,
        serial: -1,
        infrared: 0,
      })
      alt_id = status.host_id

      msg = make_message 'System', 'Guest registered with WebSockets'
      ActionCable.server.broadcast "#{secret}/chat", msg
    else
      reject # Link is full; can't subscribe
      return
    end

    status.commit

    stream_from "#{secret}/#{next_to_sub}"

    ActionCable.server.broadcast "#{secret}/#{next_to_sub}", status.to_json
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    redis = Redis.new host: 'localhost'

    secret = data['secret']
    status = LinkStatus.new redis, secret

    if tmp = data['host']
      status.update_host data['host']

    elsif tmp = data['guest']
      status.update_guest data['guest']

    else
      raise 'No host or guest specified... fail?'
    end

    status.commit
  end
end
