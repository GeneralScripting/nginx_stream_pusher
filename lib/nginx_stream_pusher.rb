require 'addressable/uri'
require 'yajl/json_gem'
require 'net/http'
require 'net/https'

module NginxStreamPusher

  extend self

  RootCA          = '/etc/ssl/certs'
  DEFAULT_URL     = Addressable::URI.parse 'https://localhost:8123/live-pub'
  DEFAULT_TIMEOUT = 10

  @@base_url = nil
  def base_url=(url)
    @@base_url = Addressable::URI.parse url
  end
  def base_url
    @@base_url || DEFAULT_URL
  end

  @@user = nil
  def base_url=(username)
    @@user = username
  end
  def user
    @@user
  end

  @@pass = nil
  def pass=(password)
    @@pass = password
  end
  def pass
    @@pass
  end

  @@timeout = nil
  def timeout=(new_timeout)
    @@timeout = new_timeout
  end
  def timeout
    @@timeout || DEFAULT_TIMEOUT
  end

  def publish!(channel, text)
    url = base_url.dup
    url.query_values = { :id => channel }
    post_url(url, text)
  end



 private

  def post_url(url, data)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    http.read_timeout = timeout
    if File.directory? RootCA
      http.ca_path = RootCA
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
    else
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    req = Net::HTTP::Post.new(url.request_uri, 'User-agent' => 'NginxStreamPusher Ruby Client')
    req.basic_auth user, pass  if user || pass
    req.body = data
    
    response = http.request(req)
    
    case response
    when Net::HTTPSuccess, Net::HTTPOK
      response.body
    else
      response.error!
    end
  end

end