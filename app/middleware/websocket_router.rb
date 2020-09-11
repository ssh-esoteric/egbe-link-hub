class WebsocketRouter
  REGEXP = %r{/links/(?<secret>[ps][0-9a-zA-Z_-]+)/api}

  def initialize(app)
    @app = app
  end

  def call(env)
    uri = env['REQUEST_URI']
    upgrade = env['HTTP_UPGRADE']

    match = REGEXP.match uri
    if match
      env['egbe.websocket_router.secret'] = match[:secret]

      if upgrade =~ /websocket/
        return ActionCable.server.call env
      end
    end

    @app.call env
  end
end
