# frozen_string_literal: true

class LinksController < ApplicationController
  protect_from_forgery with: :null_session

  def send_message
    link = Link.find_by secret: params[:secret]
    name = params[:name].to_s.strip
    text = params[:text].to_s.strip

    msg = {
      type: 'message',
      name: name,
      text: text,
      timestamp: Time.now.strftime('%s').to_i,
    }
    LinkChannel.broadcast_to link, msg
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
    accept = request.headers[:accept]
    role = case accept
    when 'application/prs.egbe.msg-v0.host';  :host
    when 'application/prs.egbe.msg-v0.guest'; :guest
    when 'application/prs.egbe.msg-v0.sync';  :sync
    else return redirect_to "/links/#{id}"
    end

    # For performance, don't do this check on :host or :guest
    if role == :sync
      @link = Link.where(secret: id).first

      return render plain: 'e Link not found', status: 404 if !@link
    end

    req = request.get? ? nil : ApiMessage.parse(request.body.read.chomp)

    handler = ApiMessageHandler.new redis, id, role, req

    return render plain: handler.rsp.to_s
  ensure
    redis.close if redis
  end

  private

  def find_link(id)
    search = Link.where(link_id: id).or Link.where(secret: id)
    search.first
  end
end
