#!/usr/bin/ruby
# encoding: UTF-8
require 'fileutils'

 # # For creating a new release branch from develop # #
#                                                      #
  DESC = <<-DESCRIPTION

    1. Check out the develop branch
    2. Get version from pom.xml in current directory
    3. Branch out a new release branch
    4. Update POM versions on both branches
  DESCRIPTION
#                                                      #
  # # # # # # # # # # # # # # # # # # # # # # # # # # #

def sio_release_branch!
  finish! unless branching_confirmed
  
  develop = "develop"

  git_check_out develop

  finish! "👍"

  develop_version = get_version_from_pom
  new_dev_version = increment_snapshot_version(develop_version)
  release_version = get_release_version(develop_version)
  release         = get_release_branch_name(release_version)

  git_branch_out release

  set_pom_versions_as release_version

  git_check_out develop

  set_pom_versions_as new_dev_version

  git_check_out release

  finish! "👍"
  

# verify_version_format(develop_version)

end


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

def get_version_from_pom()
  path = "#{Dir.pwd}/pom.xml"
  puts "\n >> Getting version from: " << path.pink
  unless File.exists? path
    error_message "File does not exist", path
    finish!
  end
  File.open(path) do |f|
    f.each_line do |line|
      m = line.match(/<version>(.*)<\/version>/)
      return m[1] if m
    end
  end
  error_message "Could not find version from", path
  finish!
end

def increment_snapshot_version(dev_version)
  # NB: verify dev is a snapshot version?
  # not implemented
  ""
end

def get_release_version(dev_version)
  # NB: verify dev is a snapshot version?
  # not implemented
  ""
end

def get_release_branch_name(release_version)
  # not implemented
  ""
end

def set_pom_versions_as(version)
  # not implemented
end


def git_check_out(branch)
  unless current_branch.include? branch
    info_message "Checking out", branch
    run "git checkout #{branch} -q"
  end
end

def git_branch_out(branch)
  info_message "Branching out to", branch
  run "git checkout -b #{branch} -q"
end

def current_branch
  run "git rev-parse --abbrev-ref HEAD"
end

def run(command)
  res = %x[ #{command} ]
  unless $?.exitstatus === 0
    error_message "Operation failed while doing", command
    finish!
  end
  res
end

def info_message(text, reason)
  puts "     > #{text}: [ ".yellow << "#{reason}".green << " ]".yellow
end

def error_message(text, reason)
  puts "   !> #{text}: [ ".red << "#{reason}" << " ]".red
end

def finish!(status="👎")
  puts "\n >> Done " << status
  exit
end

def branching_confirmed
  puts <<-END

   #{"This script will:".yellow} #{DESC}
   END
   prompt("  Confirm release branching:".yellow + " [#{'y'.green}/#{'n'.red}] ") =~ /^y$|^Y$|^yes$|^Yes$/
end

def prompt(*args)
    print(*args)
    $stdin.gets.chomp
end


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Colorization

class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end

# # # # # # # # # # # # # # # # # # # # # # # # # # # #

sio_release_branch!