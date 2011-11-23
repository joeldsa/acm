require "acm/config"
require "acm/api_controller"

require "sequel"
require "yajl"

module ACM::Controller

  class RackController
    PUBLIC_URLS = ["/info"]

    def initialize
      super
      @logger = ACM::Config.logger
      api_controller = ApiController.new

      @logger.debug("Created ApiController")

      @app = Rack::Auth::Basic.new(api_controller) do |username, password|
        [username, password] == [ACM::Config.basic_auth[:user], ACM::Config.basic_auth[:password]]
      end
      @app.realm = "ACM"

    end

    def call(env)

      @logger.debug("Received call with for \
                    #{env["rack.url_scheme"]} \
                    from #{env["REMOTE_ADDR"]} #{env["HTTP_HOST"]}\
                    operation #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}#{env["QUERY_STRING"]}")

      start_time = Time.now
      status, headers, body = @app.call(env)
      end_time = Time.now
      @logger.debug("#{end_time - start_time}ms for operation #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}#{env["QUERY_STRING"]}")
      headers["Date"] = Time.now.rfc822 # As thin doesn't inject date

      @logger.debug("Sending response Status: #{status} Headers: #{headers} Body: #{body}")
      [ status, headers, body ]
    end

  end

end
