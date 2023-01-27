ENV['APP_ENV'] = 'test'

require './nodes'
require 'rspec'
require 'rack/test'

RSpec.describe 'Node Tree' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "produces expected output for part 1" do
    get "/load_sample_nodes"
    inputs = [
      [5497637, 2820230],
      [5497637, 130],
      [5497637, 4430546],
      [9, 4430546],
      [4430546, 4430546],
    ]
    outputs = [
      {root_id: 130, lowest_common_ancestor: 125, depth: 2},
      {root_id: 130, lowest_common_ancestor: 130, depth: 1},
      {root_id: 130, lowest_common_ancestor: 4430546, depth: 3},
      {root_id: nil, lowest_common_ancestor: nil, depth: nil},
      {root_id: 130, lowest_common_ancestor: 4430546, depth: 3},
    ]
    inputs.each_with_index do |(a, b), i|
      get "common_ancestor?a=#{a}&b=#{b}"
      expect(last_response.body).to eq(outputs[i].to_json)
    end
  end

  it "produces expected output for part 2" do
    get "/load_sample_nodes"
    get "/load_sample_birds"
    inputs = [
      [2820230, 4430546],
      [130],
      [130, 125],
    ]
    outputs = [
      [20, 25, 30, 50],
      [20, 25, 30, 35, 40, 45, 50],
      [20, 25, 30, 35, 40, 45, 50],
    ]
    inputs.each_with_index do |nodes, i|
      get "node_birds?" + nodes.map{ |n| "nodes[]=#{n}" }.join('&')
      expect(JSON.parse(last_response.body).sort).to eq(outputs[i])
    end
  end

  it "produces expected output for part 3" do
    get "/load_ltree_nodes"
    get "/load_sample_birds"
    inputs = [
      [2820230, 4430546],
      [130],
      [130, 125],
    ]
    outputs = [
      [20, 25, 30, 50],
      [20, 25, 30, 35, 40, 45, 50],
      [20, 25, 30, 35, 40, 45, 50],
    ]
    inputs.each_with_index do |nodes, i|
      get "tree_birds?" + nodes.map{ |n| "nodes[]=#{n}" }.join('&')
      expect(JSON.parse(last_response.body).sort).to eq(outputs[i])
    end
  end
end
