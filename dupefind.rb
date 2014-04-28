require 'text'

def offset_to_index(offset, end_offsets)
  return nil if offset >= end_offsets.last
  end_offsets.each_with_index { |o,i| return i if offset < o }
end

def get_random_query_offset(all_contents, end_offsets, search_len)
  # Needs to be contained within one file
  valid_search = false
  while !valid_search
    offset = rand(0..all_contents.length - search_len)
    file_index = offset_to_index(offset, end_offsets)
    valid_search = file_index == offset_to_index(offset + search_len, end_offsets)
  end
  return { 
    str: all_contents[offset..offset + search_len],
    file_index: file_index,
    offset: offset 
  }
end

# Our similarity measuring tool
white = Text::WhiteSimilarity.new

# Variables controlling behaviour
MAX_SEARCH_LEN  = 100
MIN_SEARCH_LEN  = 50
NUM_SEARCHES    = 50
NUM_MATCHES     = 50

# Get all text from each file
files = []
contents = {}
all_contents = ''
end_offsets = []
results = []

end_offset = 0
Dir.glob('../tojam2014/source/**/*.hx') do |f|
  files << f
  # c = File.read(f).gsub(/\s+/, '')
  # c = File.read(f)
  c = File.read(f).gsub(/\s{2,}/, '')
  contents[f] = c
  all_contents << c
  end_offset += c.length
  end_offsets << end_offset
end

# puts "Total Code Length: #{all_contents.length} characters" 
# puts "File Offsets: #{end_offsets}"

results = {}

# Generate strings to search for
for i in 1..NUM_SEARCHES
  
  search_len = rand(MIN_SEARCH_LEN..MAX_SEARCH_LEN)
  search = get_random_query_offset(all_contents, end_offsets, search_len)

  results[search] = []

  # Try it in various spots
  for j in 1..NUM_MATCHES

    # Only allow non-overlapping search/match combos
    valid_match = false
    while !valid_match
      match = get_random_query_offset(all_contents, end_offsets, search_len)
      valid_match = !((search[:offset] <= match[:offset] + search_len) && (match[:offset] <= search[:offset] + search_len))
    end

    match[:similarity] = white.similarity(search[:str], match[:str])
    results[search] << match

  end

end

# # Calculate average similarity for each search across its matches
# results.each do |s,ms|
#   s[:avg_sim] = 0
#   ms.each do |m|
#     s[:avg_sim] += m[:similarity]
#   end
#   s[:avg_sim] /= ms.length
# end

# Calculate average similarity for each search across its matches
results.each do |s,ms|
  s[:max_sim] = 0
  ms.each do |m|
    s[:max_sim] = [s[:max_sim], m[:similarity]].max
  end
end

# # Sort by average match
# sorted_results = results.sort_by{ |s,ms| s[:avg_sim] }.reverse

# Sort by max match
sorted_results = results.sort_by{ |s,ms| s[:max_sim] }.reverse

# For top searches, show top match
top_search, top_matches = sorted_results.first
sorted_top_matches = top_matches.sort_by{ |m| m[:similarity] }.reverse

top_match = sorted_top_matches.first

p top_search
p top_match

puts "Top Search: #{top_search[:str]}\n\n"
puts "Top Search File: #{files[top_search[:file_index]]}\n\n"
puts "Top Search Offset: #{top_search[:offset]}\n\n"
puts "Top Match: #{top_match[:str]}\n\n"
puts "Top Match File: #{files[top_match[:file_index]]}\n\n"
puts "Top Match Offset: #{top_match[:offset]}\n\n"
puts "Similarity: #{top_match[:similarity]}\n\n"
