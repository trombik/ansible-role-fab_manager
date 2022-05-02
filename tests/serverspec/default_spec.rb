require "spec_helper"
require "serverspec"

user    = "fab"
group   = "fab"
home_dir = "/usr/local/#{user}"
repo_dir = "#{home_dir}/fab_manager"
env_file  = "#{repo_dir}/.env"
ports   = []
log_dir = "#{repo_dir}/log"

case os[:family]
when "freebsd"
end

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
  it { should have_home_directory home_dir }
end

describe file(repo_dir) do
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 755 }
end

describe file(log_dir) do
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 755 }
end

describe file(env_file) do
  it { should be_file }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 640 }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
