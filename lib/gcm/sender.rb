require 'typhoeus'

module GCM
    class Sender

      attr_accessor :api_key, :api_status, :handlers, :hydra, :requests

      OPTIONAL_OPTIONS = {
        :collapse_key     => String, 
        :data             => Hash, 
        :delay_while_idle => Fixnum, 
        :time_to_live     => Fixnum
      }

      def initialize(api_key)
        @api_key  = api_key
        @handlers = []
      end

      #http://developer.android.com/guide/google/gcm/gcm.html#server
      def send_async(registration_ids, opts={}, handler=nil)

        headers = {
          'Content-Type'  => 'application/json',
          'Authorization' => sprintf("key=%s", @api_key)
        }

        body = {
          'registration_ids' => registration_ids,
        }

        #fill up option
        OPTIONAL_OPTIONS.each do | key, type |
          if opts.key?(key)
            raise "#{key} should be Type #{type}" unless opts[key].is_a?(type)
            body[key] = opts[key]
          end
        end

        request = Typhoeus::Request.new(
          'https://android.googleapis.com/gcm/send',
          :headers => headers,
          :method  => :post,
          :body    => body.to_json
        )

        @hydra ||= Typhoeus::Hydra.new

        request.on_complete do | response |
          handler.handle(registration_ids, opts, response)
        end

        @hydra.queue(request)

        request
      end

      def send_async_run
        # handle response according to http://developer.android.com/guide/google/gcm/gcm.html#response
        @hydra.run
      end

    end
end
