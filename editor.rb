#!/usr/bin/env ruby
=begin
TODO List Here / Notes
----------------------

=end

# Include external libraries
require 'yaml'
require 'fileutils'
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
include Gosu
# ---

# Include my std lib
require_relative 'lib/lib.rb'
require_relative 'lib/lib_misc.rb'
require_relative 'lib/lib_alphabet.rb'
# ---


# Temp values
$CONFIG = {}
$PROJECT = nil


def draw_square(window, x, y, z, width, height, color = 0xffffffff)
  window.draw_quad(x, y, color, x + width, y, color, x, y + height, color, x + width, y + height, color, z)
end


class Editor < Gosu::Window
  def initialize()
    super($CONFIG['Window_Width'], $CONFIG['Window_Height'], false)
    self.caption = 'Cutscene Creator'
    Alphabet::initialize(self)
    @current_frame = 0
    @block_size = $CONFIG['Pixel_Size']
    File.open("#{$PROJECT}/framemap.marshal", 'r') do |file|
      @framemap = Marshal.load(file)
    end
  end # End GameWindow Initialize

  def pixel_to_cellpixel(pixel)
    return (pixel / @block_size).floor() * @block_size
  end

  def update()
    if button_down?(Gosu::Button::MsLeft) then
      if @framemap[@current_frame] == nil then
        @framemap[@current_frame] = Hash.new()
      end
      @framemap[@current_frame][[pixel_to_cellpixel(mouse_x), pixel_to_cellpixel(mouse_y)]] = 0xFFFFFFFF
    elsif button_down?(Gosu::Button::MsRight) then
      unless @framemap[@current_frame] == nil
        @framemap[@current_frame].delete([pixel_to_cellpixel(mouse_x), pixel_to_cellpixel(mouse_y)])
      end
    end
  end # End GameWindow Update

  def draw()
    draw_square(self, pixel_to_cellpixel(mouse_x), pixel_to_cellpixel(mouse_y), 1, @block_size, @block_size, 0x7f0000ff)
    Alphabet::draw_text(@current_frame, 0, 0, 2, 4)
    unless @framemap[@current_frame] == nil
      @framemap[@current_frame].each do |key, value|
        draw_square(self, key[0], key[1], 0, @block_size, @block_size, value)
      end
    end
  end # End GameWindow Draw

  def button_down(id)
    if id == Gosu::Button::KbEscape then
      close()
    elsif id == Gosu::Button::KbLeft then
      if @current_frame > 0 then
        @current_frame -= 1
      end
    elsif id == Gosu::Button::KbRight then
      @current_frame += 1
    end
  end

  def needs_cursor?()
    return true
  end

  def clean_framemap()
    @framemap.each_index do |i|
      @framemap[i] = nil if @framemap[i] == nil or @framemap[i].empty?()
    end
    @framemap = remove_trailing_nils(@framemap)
  end

  def close()
    clean_framemap()
    File.open("#{$PROJECT}/framemap.marshal", 'w+') do |file|
      Marshal.dump(@framemap, file)
    end
    super()
  end
end # End GameWindow class


def load_config_file()
  File.open("#{$PROJECT}/config.yml", 'r') do |file|
    $CONFIG = YAML::load(file.read())
  end
end

def open_editor()
  load_config_file()
  Editor.new().show()
end


puts '----------------'
puts 'Cut-scene creator'
puts '----------------'
print "\n"

quit = false
until quit do
  print '> '
  input = gets().chomp().split(' ')
  print "\n"
  unless input.empty?
    command = input.shift()
    args = input
    if command.casecmp('help') == 0 or command == '?' then
      # Display help
    elsif command.casecmp('project') == 0 then
      if args.count() == 2 and ['create', 'load'].include?(args[0]) then
        if args[0] == 'create' then
          name = args[1]
          if directory_exists?(name) then
            puts 'Project already exists!'
          else
            puts 'Please enter'
            print 'Window width: '
            window_width = gets().chomp().to_i()
            print 'Window height: '
            window_height = gets().chomp().to_i()
            print 'Framerate: '
            framerate = gets().chomp().to_i()
            print 'Pixel size: '
            pixel_size = gets().chomp().to_i()
            FileUtils.mkdir(name)
            # Create the config file
            File.open("#{name}/config.yml", 'w+') do |file|
              file.print({'Window_Width' => window_width, 'Window_Height' => window_height, 'Framerate' => framerate, 'Pixel_Size' => pixel_size}.to_yaml())
            end
            # Create an empty framemap file
            File.open("#{name}/framemap.marshal", 'w+') do |file|
              Marshal.dump(Array.new(), file)
            end
            $PROJECT = name
            puts "#{name} created, and set as current project."
          end
        elsif args[0] == 'load' then
          name = args[1]
          if directory_exists?(name) and name != 'lib' then
            $PROJECT = name
            puts "#{name} set as current project."
          else
            puts "Project: #{name} doesn't exist!"
          end
        end
      else
        puts "'project' Syntax:"
        puts 'project create projectnamehere'
        puts '  Creates a project, and sets up default files'
        puts 'project load projectnamehere'
        puts '  Loads a previously created project'
      end
    elsif command.casecmp('editor') == 0 then
      if $PROJECT == nil then
        puts 'No project loaded!'
      else
        quit = true
        open_editor()
      end
    elsif command.casecmp('exit') == 0 or command.casecmp('quit') == 0 then
      quit = true
    else
      puts "Unknown command: #{command}"
    end
  end
  print "\n"
end

