# frozen_string_literal: true

class LinksController < ApplicationController
  protect_from_forgery with: :null_session

  def api
    # TODO: Debug a weird race condition when using Rails.cache.redis instead
    #       of creating and closing a new instance for each request
    redis = Redis.new host: 'localhost'

    req = request.get? ? nil : ApiMessage.parse(request.body.read.chomp)

    handler = ApiMessageHandler.new redis, params[:id], params[:role], req

    return render plain: handler.rsp.to_s
  ensure
    redis.close if redis
  end
end
