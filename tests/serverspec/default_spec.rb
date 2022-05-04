require "spec_helper"
require "serverspec"

user    = "fab"
group   = "fab"
home_dir = "/usr/local/#{user}"
repo_dir = "#{home_dir}/fab_manager"
config_dir = "#{repo_dir}/config"
env_file = "#{repo_dir}/.env"
config_database = "#{config_dir}/database.yml"
db_service = case os[:family]
             when "freebsd", "devuan"
               "postgresql"
             end
rproxy_service = case os[:family]
                 when "freebsd", "devuan"
                   "haproxy"
                 end
supervisor_service = case os[:family]
                     when "freebsd"
                       "supervisord"
                     when "devuan"
                       "supervisor"
                     end
supervisor_workers = %w[app worker]
ports = [
  80,   # reverse proxy
  5000, # the application
  5432, # postgresql
  6379  # redis
]
log_dir = "#{repo_dir}/log"

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
  it { should have_home_directory home_dir }
end

describe file(repo_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 755 }
end

describe file(log_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 755 }
end

describe file(env_file) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 640 }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

describe file(config_database) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 640 }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

describe file(env_file) do
  it { should exist }
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

describe command("cd #{repo_dir} && bundle exec gem list"), sudo: false do
  its(:stdout) { should match(/^rails\s+/) }
  its(:stderr) { should eq "" }
  its(:exit_status) { should eq 0 }
end

describe file("#{repo_dir}/node_modules") do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode 755 }
end

describe service(db_service) do
  it { should be_enabled }
  it { should be_running }
end

describe service(supervisor_service) do
  it { should be_enabled }
  it { should be_running }
end

describe service(rproxy_service) do
  it { should be_enabled }
  it { should be_running }
end

describe command("supervisorctl status") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  supervisor_workers.each do |w|
    its(:stdout) { should match(/^#{w}\s+RUNNING\s+/) }
  end
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command("curl -s http://127.0.0.1:5000") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match Regexp.escape("<title>Fab-manager</title>") }
end

describe command("curl -s http://127.0.0.1") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match Regexp.escape("<title>Fab-manager</title>") }
end
