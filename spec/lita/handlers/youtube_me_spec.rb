require "spec_helper"

describe Lita::Handlers::YoutubeMe, lita_handler: true do  
  
  let(:search_babbletron_response) { File.read(File.expand_path("../../fixtures/search_babbletron.json", __dir__)) }
  let(:search_soccer_response) { File.read(File.expand_path("../../fixtures/search_soccer.json", __dir__)) }
  let(:video_response) { File.read(File.expand_path("../../fixtures/video_nG7R.json", __dir__)) }
  let(:invalid_api_key_response) { File.read(File.expand_path("../../fixtures/invalid_api_key.json", __dir__)) }
  let(:top_result_response) { File.read(File.expand_path("../../fixtures/top_result.json", __dir__)) }
  let(:invalid_video_response) { File.read(File.expand_path("../../fixtures/invalid_video.json", __dir__)) }

  it { is_expected.to route_command("youtube me something") }
  it { is_expected.to route_command("youtube me something").to(:find_video) }

  it { is_expected.to route_command("youtube something") }
  it { is_expected.to route_command("youtube something").to(:find_video) }

  it { is_expected.to route_command("yt me something") }
  it { is_expected.to route_command("yt me something").to(:find_video) }

  it { is_expected.to route_command("yt something") }
  it { is_expected.to route_command("yt something").to(:find_video) }

  it { is_expected.to route("https://www.youtube.com/watch?v=nG7RiygTwR4&feature=youtube_gdata") }
  it { is_expected.to route("https://www.youtube.com/watch?v=nG7RiygTwR4&feature=youtube_gdata").to(:display_info) }

  it { is_expected.to route("taco https://youtu.be/nG7RiygTwR4?t=9m13s taco") }
  it { is_expected.to route("taco https://youtu.be/nG7RiygTwR4?t=9m13s taco").to(:display_info_short) }

  it "can find a youtube video with a query" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/search?key&maxResults=15&order=relevance&part=snippet&q=soccer").to_return(body: search_soccer_response)        
    send_command("youtube me soccer")
    expect(replies.count).to eq 1
    expect(replies.last).to_not be_nil
    expect(replies.last).to match(/youtube\.com/)
  end

  it "does not attempt to return a playlist" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/search?key&maxResults=15&order=relevance&part=snippet&q=babbletron%20birds").to_return(body: search_babbletron_response) 
    send_command("youtube babbletron birds")
    expect(replies.count).to eq 1
    expect(replies.last).to_not be_nil
    expect(replies.last).not_to match(/^https:\/\/www\.youtube\.com\/watch\?v=$/)
  end

  #it "displays info for a requested video when the video_info config variable is true" do    
  #  stub_request(:get, "https://www.googleapis.com/youtube/v3/search?key&maxResults=15&order=relevance&part=snippet&q=soccer").to_return(body: search_soccer_response)    
  #  stub_request(:get, %r"[https://www.googleapis.com/youtube/v3/videos?id=.*]").to_return(body: video_response)
  #  registry.config.handlers.youtube_me.video_info = true
  #  send_command("yt soccer")
  #  expect(replies.count).to eq 2
  #  expect(replies.first).to_not be_nil
  #  expect(replies.first).to match(/youtube\.com/)
  #  expect(replies.last).to_not be_nil
  #  expect(replies.last).to match(/views/)
  #end

  it "does not display info for a requested video when the video_info config variable is false" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/search?key&maxResults=15&order=relevance&part=snippet&q=soccer").to_return(body: search_soccer_response)    
    registry.config.handlers.youtube_me.video_info = false
    send_command("youtube me soccer")
    expect(replies.count).to eq 1
    expect(replies.last).to_not be_nil
    expect(replies.last).to match(/youtube\.com/)
  end

  it "displays video info for detected YouTube URLs when the detect_urls config variable is true" do        
    registry.config.handlers.youtube_me.detect_urls = true
    stub_request(:get, "https://www.googleapis.com/youtube/v3/videos?id=nG7RiygTwR4&key&part=contentDetails,snippet,statistics").to_return(body: video_response)
    send_message("taco taco https://www.youtube.com/watch?v=nG7RiygTwR4 taco taco")
    expect(replies.count).to eq 1
    expect(replies.first).to_not be_nil
    expect(replies.first).to match(/10 minutes of DJ Mbenga saying Tacos \[10:02\] by RickFreeloader on 2011-09-12 \(\S+ views, \d+% liked\)/)
  end

  it "displays video info for detected YouTu.be URLs when the detect_urls config variable is true" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/videos?id=nG7RiygTwR4&key&part=contentDetails,snippet,statistics").to_return(body: video_response)
    registry.config.handlers.youtube_me.detect_urls = true
    send_message("taco taco https://youtu.be/nG7RiygTwR4?t=9m13s taco taco")
    expect(replies.count).to eq 1
    expect(replies.first).to_not be_nil
    expect(replies.first).to match(/10 minutes of DJ Mbenga saying Tacos \[10:02\] by RickFreeloader on 2011-09-12 \(\S+ views, \d+% liked\)/)
  end

  it 'will respond with video info when given a url with multiple query params' do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/videos?id=wv7DfebpL7E&key&part=contentDetails,snippet,statistics").to_return(body: video_response)
    registry.config.handlers.youtube_me.detect_urls = true
    send_message("burrito burrito https://www.youtube.com/watch?t=81&v=wv7DfebpL7E")
    expect(replies.first).to_not be_nil
  end

  it "does not display video info for detected YouTube URLs when the detect_urls config variable is false" do
    registry.config.handlers.youtube_me.detect_urls = false
    send_message("https://www.youtube.com/watch?v=nG7RiygTwR4")
    expect(replies.count).to eq 0
  end

  it "does not send a message when the detected YouTube URL does not lead to a valid video" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/videos?id=foo&key&part=contentDetails,snippet,statistics").to_return(body: invalid_video_response)
    registry.config.handlers.youtube_me.detect_urls = true
    send_message("https://www.youtube.com/watch?v=foo")
    expect(replies.count).to eq 0
  end

  it "returns the top video in response to a query when the top_result config variable is true" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/search?key&maxResults=15&order=relevance&part=snippet&q=polica%20lay%20your%20cards%20out").to_return(body: top_result_response)
    registry.config.handlers.youtube_me.top_result = true
    send_command("yt polica lay your cards out")
    expect(replies.first).to match(/Rl03afAqeFQ/)
  end

  it "does not return a video in response to a query when the API key is invalid" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/search?key=this%20key%20doesn't%20work&maxResults=15&order=relevance&part=snippet&q=soccer").to_return(status: 400, body: invalid_api_key_response)
    registry.config.handlers.youtube_me.api_key = "this key doesn't work"
    send_command("youtube me soccer")
    expect(replies.count).to eq 0
  end

  it "does not display video info for detected YouTube URLs when the API key is invalid" do
    stub_request(:get, "https://www.googleapis.com/youtube/v3/videos?id=nG7RiygTwR4&key=this%20key%20doesn't%20work&part=contentDetails,snippet,statistics").to_return(status: 400, body: invalid_api_key_response)
    registry.config.handlers.youtube_me.detect_urls = true
    registry.config.handlers.youtube_me.api_key = "this key doesn't work"
    send_message("https://www.youtube.com/watch?v=nG7RiygTwR4")
    expect(replies.count).to eq 0
  end
end

