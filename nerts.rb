#!/usr/bin/env ruby

require 'optparse'
require 'date'

NERTS_DIR = ENV['HOME'] + "/.nerts"
NOTES_DIR = ENV['HOME'] + "/.nerts/notes"
EDITOR = "vim"

Dir.chdir(NOTES_DIR)

class Note

  attr_accessor :name
  attr_accessor :file_name
  attr_accessor :id
  attr_accessor :content

  def self.get_file_contents(file)
    opened_file = File.open(file)
    contents = opened_file.read
    #make sure it's closed to clear up a little bit of resources
    opened_file.close
    return contents
  end

  #only read the note's contents if needed.
  #it can get quite large.
  def self.get_files(read_contents)
    files = Dir.entries(".")
               .select { |file| file != "." && file != ".." }
               .sort { |x,y| File.mtime(x) <=> File.mtime(y) }

    notes = Array.new

    files.each_with_index do |file, index|
      if(read_contents)
        notes.push Note.new(file, index, self.get_file_contents(file))
      else
        notes.push Note.new(file, index)
      end
    end

    return notes
  end

  def initialize(name, id, content="")
    @name = name
    @file_name = name
    @id = id
    @content = content
  end

  def to_s
    "#{File.mtime(@file_name)}\t#{@id}\t#{@name}"
  end

  def edit
    exec("#{EDITOR} '#{NOTES_DIR}/#{@file_name}'")
  end
end

OptionParser.new do |opts|
  opts.banner = "Usage: life [options]"

  opts.on("-n note_name", String, "New Note with Name 'note_name'") do |note_name|
    suffix = ".note" + DateTime.now.strftime("%Y%m%d%H%M%S%L")
    note = Note.new(note_name + suffix, 0)
    note.edit
  end

  opts.on("-e note_id", OptionParser::DecimalInteger, "Edit note with id 'note_id'") do |note_id|
    files = Note.get_files(false)
    file = files.select {|x| x.id == note_id}[0]
    file.edit
  end

  opts.on("-l [max_id]", OptionParser::DecimalInteger, "List Notes Oldest First up to id 'max_id' if specified") do |max_id|
    files = Note.get_files(false)
    if(max_id)
      files = files.select {|x| x.id <= max_id}
    end
    files.each { |f| puts f }
  end

  opts.on("-s text", String, "Search All Notes for the specicied text") do |text|
    text.downcase!
    files = Note.get_files(true)
    files = files.select {|f| f.content.downcase[text] || f.name.downcase[text] }
    files.each { |f| puts f }
  end
end.parse!
