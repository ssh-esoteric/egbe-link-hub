# frozen_string_literal: true

class LinksController < ApplicationController
  protect_from_forgery with: :null_session

  def send_message
    secret = params[:id]
    link = Link.find_by secret: secret
    name = params[:name].to_s.strip
    text = params[:text].to_s.strip
    msg = LinkChannel.make_message(name, text)

    ActionCable.server.broadcast "#{secret}/chat", msg

    render json: msg
  end

  def index
    @links = Link.order(link_id: :desc).first(50)
  end

  def create
    @link = Link.new
    @link.name = params[:name]
    pw = params[:password].to_s

    @link.password = pw if !pw.empty?
    @link.save!

    path = @link.protected? ? @link.secret : @link.id

    redirect_to "/links/#{path}", status: 303
  end

  def read
    id = params[:id]

    @link = find_link id
    if @link.nil?
      return render template: 'links/not_found', status: 404
    end

    if @link.protected? && @link.secret != id
        return render template: 'links/login'
    end

    return render template: 'links/read'
  end

  def update
    id = params[:id]
    @link = find_link id
    if !@link
      return render template: 'links/not_found', status: 404
    end

    case params[:type]
    when 'login'
      is_valid = !!@link.authenticate(params[:password].to_s)

      return redirect_to "/links/#{is_valid ? @link.secret : @link.id}", status: 303
    else
      return render plain: "Unknown action: #{params[:type]}"
    end
  end

  def api
    # TODO: Debug a weird race condition when using Rails.cache.redis instead
    #       of creating and closing a new instance for each request
    redis = Redis.new host: 'localhost'

    id = params[:id]

    status = LinkStatus.new redis, id, wait: 3

    return render json: status if request.get?

    raise 'PATCH expected' unless request.patch?

    if tmp = params[:host]
      if status.host_id.zero? && tmp['id']
        msg = LinkChannel.make_message 'System', 'Host registered with cURL'
        ActionCable.server.broadcast "#{id}/chat", msg
      end

      status.update_host tmp
    elsif tmp = params[:guest]
      if status.guest_id.zero? && tmp['id']
        msg = LinkChannel.make_message 'System', 'Guest registered with cURL'
        ActionCable.server.broadcast "#{id}/chat", msg
      end

      status.update_guest tmp
    else
      raise 'Update must contain host or guest'
    end

    status.commit

    return render json: status
  ensure
    redis.close if redis
  end

  private

  def find_link(id)
    search = Link.where(link_id: id).or Link.where(secret: id)
    search.first
  end
end
