require 'digest/md5'

Maid.rules do

  #
  # Helper Functions
  #

  def files(paths)
    dir(paths).select { |f| File.file?(f) }
  end
 
  def size_of(path)
    File.size(path)
  end
 
  def checksum_for(path)
    Digest::MD5.hexdigest(File.read(path))
  end
 
  def dupes_in(paths)
    dupes = []
    files(paths)                             # Start by filtering out non-files
      .group_by { |f| size_of(f) }           # ... then grouping by size, since that's fast
      .reject { |s, p| p.length < 2 }        # ... and filter out any non-dupes
      .map do |size, candidates|
        dupes += candidates
          .group_by { |p| checksum_for(p) }  # Now group our candidates by a slower checksum calculation
          .reject { |c, p| p.length < 2 }    # ... and filter out any non-dupes
          .values
      end
    dupes
  end


  # 
  # Trash
  #

  rule 'Take out the Trash' do
    dir('~/.Trash/*').each do |p|
      remove(p) if accessed_at(p) > 20.days.ago
    end
  end


  #
  # Downloads
  #

  download_archive = '~/Documents/Downloads Archive/'

  rule 'Remove expendable files' do
    dir('~/Downloads/*.{csv,doc,docx,gem,vcs,ics,ppt,js,rb,xml,xlsx}').each do |p|
      trash(p) if 3.days.since?(accessed_at(p))
    end
  end

  rule 'Trash duplicate downloads' do
    dupes_in('~/Downloads/*').each do |dupes|
      # Keep the dupe with the shortest filename
      trash dupes.sort_by { |p| File.basename(p).length }[1..-1]
    end
  end

  rule 'Mac OS X applications in disk images' do
    trash(dir('~/Downloads/*.dmg'))
  end

  rule 'Mac OS X applications in zip files' do
    found = dir('~/Downloads/*.zip').select { |path|
      zipfile_contents(path).any? { |c| c.match(/\.app$/) }
    }
    trash(found)
  end

  rule 'Move Downloads to temp archive' do
    folder_name = Time.new.strftime("%Y-%m-%d")
    mkdir download_archive + folder_name
    move dir('~/Downloads/*'), download_archive + folder_name
  end

  rule 'Remove old temp archive' do
    dir(download_archive + "/*").each do |p|
      remove(p) if 60.days.since?(accessed_at(p))
    end
  end


  #
  # Desktop
  #

  rule 'Misc Screenshots' do
    # trash(dir('~/Desktop/*.*'))
    dir('~/Desktop/Screen Shot *').each do |path|
      trash(path)
    end
  end

end
