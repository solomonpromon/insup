require 'listen'
require 'pathname'

# Listens to directory changes and executes callback each time something changes
class Listener
  attr_reader :ignore_patterns, :force_polling

  FLAGS_MAP = {
    1 => Insup::TrackedFile::DELETED,
    2 => Insup::TrackedFile::MODIFIED,
    3 => Insup::TrackedFile::DELETED,
    4 => Insup::TrackedFile::NEW,
    5 => Insup::TrackedFile::UNSURE,
    6 => Insup::TrackedFile::NEW,
    7 => Insup::TrackedFile::UNSURE
  }.freeze

  def initialize(base, settings = {})
    defaults = {
      force_polling: false,
      ignore_patterns: []
    }

    @base = base
    @base_pathname = Pathname.new(@base)
    settings = defaults.merge(settings)
    @ignore_patterns = settings[:ignore_patterns]
    settings.delete(:ignore_patterns)
    @listener_options = settings
  end

  def listen
    return if @listener

    @listener =
      Listen.to(@base, @listener_options) do |modified, added, removed|
        flags = prepare_flags(modified, added, removed)
        changes = prepare_changes(flags)
        yield changes if block_given?
      end

    @listener.start
  end

  def stop
    @listener.stop if @listener
    @listener = nil
  end

  protected

  def prepare_flags(modified, added, removed)
    flags = Hash.new(0)

    added.each    { |f| flags[make_relative_path(f)] |= 4 }
    modified.each { |f| flags[make_relative_path(f)] |= 2 }
    removed.each  { |f| flags[make_relative_path(f)] |= 1 }

    flags
  end

  def make_relative_path(path)
    path = Pathname.new(path)

    if path.absolute?
      path.relative_path_from(@base_pathname).to_s
    else
      path.to_s
    end
  end

  def prepare_changes(flags)
    flags.map do |f, flag|
      file = File.expand_path(f, @base)
      next if ignore_matcher.matched?(file)
      create_tracked_file(flag, f)
    end.compact
  end

  def create_tracked_file(flags, file)
    tracked_file = Insup::TrackedFile.new(file, FLAGS_MAP[flags])
    return nil if tracked_file.unsure? && !tracked_file.exist?(@base)
    tracked_file
  end

  def ignore_matcher
    @ignore_matcher ||= ::MatchFiles.git(@base, ignore_patterns)
  end
end
