module GemMirror
  ##
  # The Source class is used for storing information about an external source
  # such as the name and the Gems to mirror.
  #
  # @!attribute [r] name
  #  @return [String]
  # @!attribute [r] host
  #  @return [String]
  # @!attribute [r] gems
  #  @return [Array]
  #
  class Source
    attr_reader :name, :host, :gems

    ##
    # @param [String] name
    # @param [String] host
    # @param [Array] gems
    #
    def initialize(name, host, gems = [])
      @name = name.downcase.gsub(/\s+/, '_')
      @host = host.chomp('/')
      @gems = gems
    end

    ##
    # Returns a new Source instance based on the current one.
    #
    # @param [Array] new_gems The gems to set, overwrites the current ones.
    # @return [Source]
    #
    def updated(new_gems)
      return self.class.new(name, host, new_gems)
    end

    ##
    # Fetches a list of all the available Gems and their versions.
    #
    # @return [String]
    #
    def fetch_versions
      return http_get(host + '/' + Configuration.versions_file).body
    end

    ##
    # Fetches the Gem specification of a Gem.
    #
    # @param [String] name
    # @param [String] version
    # @return [String]
    #
    def fetch_specification(name, version)
      r = nil
      begin
      url = host + "/quick/#{Configuration.marshal_identifier}" +
        "/#{name}-#{version}.gemspec.rz"

      r = http_get(url).body
      rescue => msg
        puts "retrying with JAVA"
        url = host + "/quick/#{Configuration.marshal_identifier}" +
          "/#{name}-#{version}-java.gemspec.rz"
        r = http_get(url).body
      end
      raise $!.message if r.nil?
      r
    end

    ##
    # Fetches the `.gem` file of a given Gem and version.
    #
    # @param [String] name
    # @param [String] version
    # @return [String]
    #
    def fetch_gem(name, version)
      r = nil
      java  = false
      begin
      puts "Fetching #{host + "/gems/#{name}-#{version}.gem"}"
      r  = http_get(host + "/gems/#{name}-#{version}.gem").body 
      rescue  => msg
        puts "retrying with JAVA"
        r  = http_get(host + "/gems/#{name}-#{version}-java.gem").body rescue nil
        java = true
      end
      raise $!.message if r.nil?
      [r, java]
    end

    ##
    # Adds a new Gem to the source.
    #
    # @param [String] name
    # @param [String] requirement
    #
    def gem(name, requirement = nil)
      gems << Gem.new(name, requirement)
    end

    private

    ##
    # Requests the given HTTP resource.
    #
    # @param [String] url
    # @return [HTTP::Message]
    #
    def http_get(url)
      response = client.get(url, :follow_redirect => true)

      unless HTTP::Status.successful?(response.status)
        raise HTTPClient::BadResponseError, response.reason
      end

      return response
    end

    ##
    # @return [HTTPClient]
    #
    def client
      return @client ||= HTTPClient.new
    end
  end # Source
end # GemMirror
