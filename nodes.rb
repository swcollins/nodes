require 'csv'
require 'sinatra'
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'])

# Part 1 - Node tree

get '/create_nodes_table' do
  DB.create_table(:nodes) do
    primary_key :id
    Integer :parent_id, index: true
  end
  200
end

get '/load_sample_nodes' do
  id_to_parent = {
    125     => 130,
    130     => nil,
    2820230 => 125,
    4430546 => 125,
    5497637 => 4430546,
  }
  DB[:nodes].truncate(cascade: true)
  id_to_parent.each do |id, parent_id|
    DB[:nodes].insert(id: id, parent_id: parent_id)
  end
  200
end

get '/load_from_csv' do
  DB[:nodes].truncate(cascade: true)
  CSV.foreach(('nodes.csv'), headers: true) do |row|
    DB[:nodes].insert(id: row['id'], parent_id: row['parent_id'])
  end
  200
end

# take two params, a and b, and it should return the root_id, lowest_common_ancestor_id, and depth of tree of the lowest common ancestor that those two node ids share
get '/common_ancestor' do # /common_ancestor?a=5497637&b=2820230
  nodes = DB[:nodes]
  a = params['a'].to_i
  b = params['b'].to_i
  root_id = lca = depth = nil
  a_lineage = []
  b_lineage = []

  # traverse up lineage for a in tree
  curr_id = a
  loop do
    a_lineage << curr_id
    node = nodes.first(id: curr_id)
    break if !node || node[:parent_id].nil?
    curr_id = node[:parent_id]
  end
  root_id = curr_id

  # traverse up lineage for b until a match in a is found
  curr_id = b
  loop do
    b_lineage << curr_id
    if a_pos = a_lineage.find_index(curr_id) # match found
      lca = curr_id
      depth = a_lineage.count - a_pos
      break
    end
    node = nodes.first(id: curr_id)
    break if !node || node[:parent_id].nil?
    curr_id = node[:parent_id]
  end

  root_id = nil if lca.nil?
  {root_id: root_id, lowest_common_ancestor: lca, depth: depth}.to_json
end

# Part 2 - Nodes have_many birds and birds belong_to nodes

get '/create_birds_table' do
  DB.create_table(:birds) do
    primary_key :id
    foreign_key :node_id, :nodes
  end
  200
end

get '/load_sample_birds' do
  bird_to_node = {
    20 => 4430546,
    25 => 4430546,
    30 => 5497637,
    35 => 130,
    40 => 125,
    45 => 125,
    50 => 2820230,
  }
  DB[:birds].truncate
  bird_to_node.each do |bird, node|
    DB[:birds].insert(id: bird, node_id: node)
  end
  200
end

# take an array of node ids and return the ids of the birds that belong to one of those nodes or any descendant nodes
get '/node_birds' do # /node_birds?nodes[]=2820230&nodes[]=4430546
  bird_nodes = params['nodes'].map(&:to_i)
  birds = node_birds(bird_nodes)
  birds.to_json
end

def node_birds(nodes) # recursive
  return [] if nodes.empty?
  birds = DB[:birds].where(node_id: nodes).map(:id)
  child_nodes = DB[:nodes].where(parent_id: nodes).map(:id)
  birds | node_birds(child_nodes)
end

# Part 3 - ltree

get '/create_node_tree' do
  DB.run "CREATE TABLE node_tree (path ltree)"
  200
end

get '/load_tree_nodes' do
  tree_nodes = [
    '130',
    '130.125',
    '130.125.2820230',
    '130.125.4430546',
    '130.125.4430546.5497637',
  ]
  DB[:node_tree].truncate
  tree_nodes.each do |path|
    DB["INSERT INTO node_tree VALUES (?)", path].insert
  end
  200
end

# take an array of node ids and return the ids of the birds that belong to one of those nodes or any descendant nodes
# /tree_birds?nodes[]=2820230&nodes[]=4430546
get '/tree_birds' do
  bird_nodes = params['nodes'].map(&:to_i)
  nodes = DB["SELECT subpath(path,-1) id FROM node_tree WHERE path ~ ?", "*.#{bird_nodes.join('|')}.*"]
  birds = DB[:birds].where(node_id: nodes.map(:id))
  birds.map(:id).to_json
end
