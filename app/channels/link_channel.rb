class LinkChannel < ApplicationCable::Channel
  def link
    Link.find_by(secret: params[:secret])
  end

  def subscribed
    # stream_from "link_channel"
    # stream_for "links/#{params[:secret]}"
    stream_for link
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
