require 'rails_helper'

describe FetchOembedData do
  describe '#call' do
    context 'with invalid url' do
      it '입력된 URL의 형식이 올바르지 않으면 에러가 발생한다' do
        expect{ FetchOembedData.call('www.invalid_url.com') }
          .to raise_error(RuntimeError, 'URL 형식이 올바르지 않습니다')
      end
    end

    context 'with network exception' do
      before :example do
        allow(OpenURI).to receive(:open_uri).and_raise(RuntimeError)
      end

      it '존재하지 않는 URL을 요청하면 에러가 발생한다.' do
        expect{ FetchOembedData.call('http://www.naver.com') }
          .to raise_error(RuntimeError, '연결에 문제가 있습니다')
      end
    end

    context 'with request exception' do
      before :example do
        allow(OpenURI).to receive(:open_uri).and_raise(OpenURI::HTTPError)
      end

      it '유효하지 않은 페이지를 요청하면 에러가 발생한다.' do
        expect{ FetchOembedData.call('http://www.google.co.kr/sorry/') }
          .to raise_error(RuntimeError)
      end
    end

    context 'with valid url' do
      let(:response_data) { "{\"type\":\"video\",\"version\":\"1.0\",\"title\":\"Test\"}" }

      before :example do
        allow(OpenURI).to receive_message_chain(:open_uri, :read).and_return(response_data)
      end

      it 'oEmbed 링크를 제공하지 않는 페이지의 경우 에러가 발생한다.' do
        allow(Nokogiri::HTML::Document).to receive_message_chain(:parse, :css)
          .and_return('')

        expect{ FetchOembedData.call('http://www.naver.com') }
          .to raise_error(RuntimeError, '정보를 가져오는데 실패했습니다')
      end

      it 'oEmbed 링크를 제공하는 페이지의 경우 oEmbed 데이터를 반환한다.' do
        allow(Nokogiri::HTML::Document).to receive_message_chain(:parse, :css, :first, :value)
          .and_return('http://test.com')

        result = FetchOembedData.call('https://giphy.com/gifs/3o7TKSha51ATTx9KzC')
        expect(result['type']).to eq 'video'
        expect(result['version']).to eq '1.0'
        expect(result['title']).to eq 'Test'
      end
    end
  end
end