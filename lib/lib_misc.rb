
require 'yaml'


module EveryModule
  @@record_calls = Hash.new()
  
  def every(amount_of_calls, &block)
    source_location = block.source_location
    # Assign the source location to a block, and amount of calls if it isn't already assigned
    if @@record_calls[source_location] == nil then
      @@record_calls[source_location] = [amount_of_calls, 0]
    end
    # Increment the counter
    @@record_calls[source_location][1] += 1
    # Check if the counter is equal to the max
    if @@record_calls[source_location][0] == @@record_calls[source_location][1] then
      # It is, so reset and call block
      @@record_calls[source_location][1] = 0
      block.call()
    end
  end
end


def remove_trailing_nils(array)
  compact_array = array.compact()
  count = 0
  match_count = 0
  while match_count < compact_array.count() do
    if array[count] == compact_array[match_count] then
      match_count += 1
    end
    count += 1
  end
  return array[0..(count-1)]
end


#
# Returns true if the directory exists (convenience method)
#
def directory_exists?(directory)
  File.directory? directory
end


#
# Does a recursive search of a directory
#
def recursive_search_directory(directory)
  result = Dir.glob(File.join(directory, '**/*'))
  result.each_index do |i|
    result[i] = nil if File.directory?(result[i])
  end
  return result.compact()
end


#
# Does a block of code verbosely regardless of the state of the $VERBOSE variable
#
def verbosely()
  if $VERBOSE then
    reset = true
  else
    reset = false
  end
  $VERBOSE = true
  yield
  $VERBOSE = reset
end


#
# Does a block of code non-verbosely regardless of the state of the $VERBOSE variable
#
def non_verbosely()
  if $VERBOSE then
    reset = true
  else
    reset = false
  end
  $VERBOSE = false
  yield
  $VERBOSE = reset
end


#
# Returns the number at nth place in the fibonacci sequence that starts at start_number
#
def fib(start_number, n)
  curr = start_number
  succ = start_number
  n.times do
    curr, succ = succ, curr + succ
  end
  return curr
end


#
# Returns a 2d array full of ' ' elements
#
def create_2d_array(width, height)
  return Array.new(height){Array.new(width){' '}}
end


#
# Returns a 3d array full of ' ' elements
#
def create_3d_array(width, height, depth)
  return Array.new(depth){create_2d_array(width, height)}
end


#
# Returns a random number between min and max
#
def random(min, max)
  srand()
  return (min..max).to_a.sort_by{rand}.pop
end


#
# Returns the contents of an entire file read into a string
#
def file_read(file)
  vputs "Reading file #{file}"
  if not File.exists?(file) then
    vputs "That file doesn't exist: #{file.inspect}"
    return ''
  end
  f = File.open(file, 'r')
    string = f.read
  f.close
  return string
end


#
# Returns the contents of a yaml file
#
def yamlfileread(file)
  if not File.exists?(file) then
    vputs "That file doesn't exist: #{file.inspect}"
    return ''
  end
  return YAML::load( File.open(file, 'r') )
end


#
# Creates a file with filename file, and fills it with file_contents
#
def create_file(file, file_contents)
  vputs "Creating file: #{file}"
  begin
    File.open(file, 'w+') do |f|  # open file for update
      f.print file_contents       # write file_contents to the file
    end                           # file is automatically closed
  rescue Exception
  end
end

#
# Returns whether or not a given angle is between min_angle and max_angle
#
def angle_in_range?(angle, min_angle, max_angle)
  angle %= 360#=#
  min_angle %= 360#=#
  max_angle %= 360#=#
  if angle < 180 then
    angle += 360
  end
  if min_angle < 180 then
    min_angle += 360
  end
  if max_angle < 180 then
    max_angle += 360
  end
  return (angle >= min_angle) && (angle <= max_angle)
end


#
# Returns a number from number as close to target_number as rate will allow
#
def smoother(number, target_number, rate)
  rate = rate.abs
  if (number - target_number).abs > rate then
    if number < target_number then
      return (number + rate)
    else # number > target_number
      return (number - rate)
    end
  else
    return target_number
  end
end


#
# Returns an angle from angle as close to target_angle as rate will allow
#
def angle_smoother(angle, target_angle, rate)
  # Fix the angles
  angle %= 360 #=# Geany, fix your syntax highlighting!
  target_angle %= 360 #=
  # Calculate the change
  if angle < 180 then
    change = angle * -1
  elsif angle == 180 then
    change = 180
  else # angle > 180
    change = 360 - angle
  end
  # Get the transitioned target angle
  target_angle = (target_angle + change) % 360
  # Calculate the new angle, depending on rate, and return it
  if target_angle < 180 then # cw
    angle = 0
  elsif target_angle == 180 then # random
    if rand(2) == 0 then
      angle = 360
    else
      angle = 0
    end
  else # ccw
    angle = 360
  end
  return (smoother(angle, target_angle, rate) - change) % 360
end


def get_number_range(first_number, second_number)
  first_number = first_number.round()
  second_number = second_number.round()
  numbers_hash = Hash.new()
  numbers_hash[first_number] = true
  numbers_hash[second_number] = true
  return [first_number] if numbers_hash.count() == 1
  min, max = numbers_hash.keys().sort()
  element_count = (max - min) + 1
  count = min
  until numbers_hash.count() == element_count
    count += 1
    numbers_hash[count] = true
  end
  return numbers_hash.keys().sort()
end


#
# Used for line of sight, not made by me
#
def get_line(x0,y0,x1,y1)
  points = []
  steep = ((y1-y0).abs) > ((x1-x0).abs)
  if steep
    x0,y0 = y0,x0
    x1,y1 = y1,x1
  end
  if x0 > x1
    x0,x1 = x1,x0
    y0,y1 = y1,y0
  end
  deltax = x1-x0
  deltay = (y1-y0).abs
  error = (deltax / 2).to_i
  y = y0
  ystep = nil
  if y0 < y1
    ystep = 1
  else
    ystep = -1
  end
  for x in x0..x1
    if steep
      points << {:x => y, :y => x}
    else
      points << {:x => x, :y => y}
    end
    error -= deltay
    if error < 0
      y += ystep
      error += deltax
    end
  end
  return points
end


__END__
