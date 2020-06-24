class WebsocketRouter
  def initialize(app)
    @app = app
  end

  def call(env)
    uri = env['REQUEST_URI']
    upgrade = env['HTTP_UPGRADE']

    if upgrade =~ /websocket/ && uri =~ %r{/links/(?<secret>[ps][0-9a-zA-Z_-]+)/api}
      ActionCable.server.call env
    else
      @app.call env
    end
  end
end
