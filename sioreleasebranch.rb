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

  verify_that_working_directory_is_clean

  develop = "develop"

  git_check_out develop

  git_pull

  develop_version = get_version_from_pom
  new_dev_version = increment_version(develop_version)
  release_version = get_release_version(develop_version)
  release         = get_release_branch(release_version)

  git_branch_out release

  set_pom_versions_as release_version

  git_check_out develop

  set_pom_versions_as new_dev_version

  git_check_out release

  finish! "👍"
end


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

def verify_that_working_directory_is_clean()
  puts
  info_message "Checking that working directory is clean".yellow
  unless run("git status").include? "working directory clean"
    error_message "Clean up the working directory before running this script! Check with", "git status"
    finish!
  end
end

def get_version_from_pom()
  path = "#{Dir.pwd}/pom.xml"
  info_message "Getting version from: ".yellow + path.pink
  unless File.exists? path
    error_message "File does not exist", path
    finish!
  end
  File.open(path) do |f|
    f.each_line do |line|
      ver = line.match(/<version>(.*)<\/version>/)
      if ver
        check_version_format(ver[1])
        return ver[1]
      end
    end
  end
  error_message "Could not find version from", path
  finish!
end

def check_version_format(version)
  m = version.match(/(\w+)\.(\w+)\.(\w+)-SNAPSHOT/)
  unless m and m[1] and m[2] and m[3]
    error_message "Incompatible version format. Expected format: <x.y.z-SNAPSHOT>. Recieved", version
    finish!
  end
end

def increment_version(dev_version)
  m = dev_version.match(/(\w+)\.(\w+)\.(\w+)-SNAPSHOT/)
  "#{m[1]}.#{m[2].to_i + 1}.#{m[3]}-SNAPSHOT"
end

def get_release_version(dev_version)
  dev_version.tr("-SNAPSHOT", "")
end

def get_release_branch(release_version)
  m = release_version.match(/(\w+)\.(\w+)\.\w+/)
  "release-#{m[1]}.#{m[2]}"
end

def set_pom_versions_as(version)
  info_message "Setting POM versions to", version
  run "changePomVersion #{version}"
  run "git commit -am 'Bumped version #{version}' -q"
  run "git push -q origin #{current_branch}"
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
  run "git push --set-upstream origin #{branch} -q"
end

def git_pull
  branch = current_branch.chomp
  info_message "Pulling changes from", branch
  run "git pull origin #{branch} -q"
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

def info_message(text, reason = nil)
  if reason
    puts "    > #{text}: [ ".yellow << reason.green << " ]".yellow
  else
    puts "    > ".yellow + text
  end
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
   prompt("\n ?> Confirm release branching:"+ " [#{'y'.pink}/#{'n'.pink}] ") =~ /^y$|^Y$|^yes$|^Yes$/
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