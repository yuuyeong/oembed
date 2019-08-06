require 'open-uri'
require 'nokogiri'

class FetchOembedData 
  def initialize(url)
    @url = url
  end

  def self.call(args)
    new(args).call
  end

  def call
    check_url_validation
    @oembed_url = get_oembed_request_url
    return get_oembed_data
  end

  private

  def check_url_validation
    raise 'URL 형식이 올바르지 않습니다' unless 
    Regexp.new('^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$')
      .match?(@url)
  end

  def get_oembed_request_url
    provider_data = get_provider_data
    provider_data.each do |key, values|
      if values[:schemes].any? { |scheme| scheme.match?(@url) }
        return create_endpoint(values[:url])
      end
    end

    return discover_oembed_url
  end

  def get_provider_data
    data = {}
    PR_CONFIG.each do |key, values|
      data[key] = create_regex_schemes(values)
    end
    return data
  end

  def create_regex_schemes(values)
    schemes = (values['endpoints']['schemes'] || values['provider_url'] + '*').split(' ')
    return {
      schemes: schemes.map {|scheme| Regexp.new('^' + scheme.gsub('*', '.*') + '$')},
      url: values['endpoints']['url']
    }
  end

  def discover_oembed_url
    response = request_to_url(@url)
    parsed_body = Nokogiri::HTML(response)
    oembed_link = parsed_body.css('link[type="application/json+oembed"]/@href') || 
                    parsed_body.css('link[type="text/xml+oembed/"]/@href')

    raise '정보를 가져오는데 실패했습니다' if oembed_link.blank?

    return oembed_link.first.value
  end

  def create_endpoint(oembed_host)
    return oembed_host.gsub('{format}', 'json') + '?url=' + @url
  end

  def request_to_url(url)
    response = open(url).read
  rescue OpenURI::HTTPError => e
    raise "#{e.message}"
  rescue
    raise '연결에 문제가 있습니다'
  end

  def get_oembed_data
    response = request_to_url(@oembed_url)
    parsed_body = JSON.parse(response)
    return parsed_body
  end
end
