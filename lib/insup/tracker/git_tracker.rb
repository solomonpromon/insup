require_relative('../git')

# Git tracker: tracks files by evaluating changes in Git repo
class Insup::Tracker::GitTracker < Insup::Tracker

  def initialize config = nil
    super
    @git = ::Insup::Git.new(@path)
  end

  def changes
    track = tracked_locations
    res = status.select do |x|
      track.any? {|t| x.path.start_with? t}
    end
  end

  private

  STATUS_MAP = {
    'A' => Insup::TrackedFile::NEW,
    'M' => Insup::TrackedFile::MODIFIED,
    'D' => Insup::TrackedFile::DELETED
  }

  def status
    changed = @git.status.select do |x,v|
      v[:untracked] || (['A','M','D'].include? v[:type])
    end

    changed.map do |x, v|
      if v[:untracked]
        Insup::TrackedFile.new v[:path], Insup::TrackedFile::NEW
      else
        Insup::TrackedFile.new v[:path], STATUS_MAP[v[:type]]
      end
    end
  end

end
